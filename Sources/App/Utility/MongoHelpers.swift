//
//  MongoHelpers.swift
//  
//
//  Created by John Forde on 5/08/22.
//

import Foundation
import Vapor
import MongoDBVapor
import Models

extension MongoProduct: Content {}
extension MongoOrder: Content {}
extension MongoStockPurchase: Content {}
extension MongoReservation: Content {}
extension Reservation: Content {}

extension Request {
  func mongoInsert<T: MongoIdentifiable>(_ element: T, into collection: MongoCollection<T>) async throws -> T {
    var newElement = element
    do {
      let result = try await collection.insertOne(element) // Use the result to update the objectId
      newElement._id = result?.insertedID.objectIDValue
      return newElement
    } catch {
      // Give a more helpful error message in case of a duplicate key error.
      if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
        throw Abort(.conflict, reason: "\(element) already exists!")
      }
      throw Abort(.internalServerError, reason: "Failed to save new order: \(error)")
    }
  }

  func mongoUpdate<T>(filter: BSONDocument, updateDocument: BSONDocument, collection: MongoCollection<T>) async throws -> Response {
    do {
      // since we aren't using an unacknowledged write concern we can expect updateOne to return a non-nil result.
      guard let result = try await collection.updateOne(
        filter: filter,
        update: updateDocument
      ) else {
        throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
      }
      print("updateDocument: \(updateDocument)")
      guard result.matchedCount == 1 else {
        throw Abort(.notFound, reason: "No object found")
      }
      return Response(status: .ok)
    } catch {
      throw Abort(.internalServerError, reason: "Failed to update object: \(error)")
    }
  }

  func mongoUpsert<T>(filter: BSONDocument, updateDocument: BSONDocument, collection: MongoCollection<T>) async throws -> Response {
    do {
      // since we aren't using an unacknowledged write concern we can expect updateOne to return a non-nil result.
      guard let result = try await collection.updateOne(
        filter: filter,
        update: updateDocument,
        options: UpdateOptions(upsert: true)
      ) else {
        throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
      }
      print("updateDocument: \(updateDocument)")
      guard result.matchedCount == 1 else {
        throw Abort(.notFound, reason: "No object found")
      }
      return Response(status: .ok)
    } catch {
      print("error.localizedDescription: \(error.localizedDescription)")
      if error.localizedDescription == "Abort.404: No object found" {
        return Response(status: .ok)
      }
      throw Abort(.internalServerError, reason: "Failed to update object: \(error)")
    }
  }

  func mongoDelete<T>(filter: BSONDocument, collection: MongoCollection<T>) async throws -> Response {
    do {
      // since we aren't using an unacknowledged write concern we can expect deleteOne to return a non-nil result.
      guard let result = try await productCollection.deleteOne(filter) else {
        throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
      }
      guard result.deletedCount == 1 else {
        throw Abort(.notFound, reason: "No product with matching id")
      }
      return Response(status: .ok)
    } catch {
      throw Abort(.internalServerError, reason: "Failed to delete product: \(error)")
    }
  }

  func getParameterString(parameterName: String) throws -> BSONDocument {
    guard let value = self.parameters.get(parameterName) else {
      throw Abort(.internalServerError, reason: "Request unexpectedly missing \(parameterName) parameter")
    }
    return [parameterName: .string(value)]
  }

  func getParameterId(parameterName: String) throws -> BSONDocument {
    guard let value = self.parameters.get(parameterName) else {
      throw Abort(.internalServerError, reason: "Request unexpectedly missing \(parameterName) parameter")
    }
    return [parameterName: .objectID(try BSONObjectID(value))]
  }
}
