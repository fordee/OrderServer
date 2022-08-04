//
//  MongoHelpers.swift
//  
//
//  Created by John Forde on 5/08/22.
//

import Foundation
import Vapor
import MongoDBVapor

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
      print("result: \(result)")
      guard result.matchedCount == 1 else {
        throw Abort(.notFound, reason: "No order found")
      }
      return Response(status: .ok)
    } catch {
      throw Abort(.internalServerError, reason: "Failed to update order: \(error)")
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
