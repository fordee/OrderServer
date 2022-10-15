
function formatNumberWithDollar(number) {
  let formatting_options = {
  style: 'currency',
  currency: 'USD',
  minimumFractionDigits: 2,
  }
  let dollarString = new Intl.NumberFormat("en-US", formatting_options);
  let finalString = dollarString.format(number);
  return finalString;
}

function calculateTotals() {
  var prices = $("tr").find("#price");
  var quantities = $("tr").find("#quantity");//.find("input");
  var totals = $("tr").find("#total");
  var grandTotal = 0
  console.log(totals.length);
  if (quantities.length > 0) {
    for (let index = 0; index < quantities.length; index++) {
      let tot = quantities[index].value * prices[index].innerText.replace("$", "");
      grandTotal += tot;
      totals[index].innerText = formatNumberWithDollar(tot);
      prices[index].innerText = formatNumberWithDollar(prices[index].innerText.replace("$", ""));
      console.log(quantities[index].value)
    }
    $("tfoot td")[3].innerText = formatNumberWithDollar(grandTotal);
  }
}

function calculateTotals2() {
  var prices = $("tr").find("#price");
  var quantities = $("tr").find("#quantity");//.find("input");
  var totals = $("tr").find("#total");
  var grandTotal = 0
  console.log("quantities.length");
  console.log(quantities.length);
  if (quantities.length > 0) {
    for (let index = 0; index < quantities.length; index++) {
      let tot = quantities[index].innerText * prices[index].innerText.replace("$", "");
      grandTotal += tot;
      totals[index].innerText = formatNumberWithDollar(tot);
      prices[index].innerText = formatNumberWithDollar(prices[index].innerText.replace("$", ""));
      console.log(quantities[index].innerText)
    }
    $("tfoot td")[3].innerText = formatNumberWithDollar(grandTotal);
  }
}

function processOrder() {
  var orderId = $("\#orderId").val();
  var products = $("tr").find("#productId");
  var quantities = $("tr").find("input");
  var prices = $("tr").find("#price");
  var productIds = [];
  var quantityValues = [];
  var priceValues = [];
  if (quantities.length > 0) {
    for (let index = 0; index < quantities.length; index++) {
      productIds[index] = products[index].innerText;
      quantityValues[index] = parseInt(quantities[index].value);
      priceValues[index] = parseFloat(prices[index].innerText.replace("$", ""));
    };
  }

  // Update the status to "awaiting confirmation"?
  $.ajax({
  type:'PATCH',
    contentType : 'application/json',
  url:'/api/mongo/orders/' + orderId + '/updateStatusItems',
    // Serialize request data to extended JSON. We use extended JSON
    // both here, and for serializing/deserializing request data on
    // the backend, in order to ensure all MongoDB type information
    // is preserved.
    // See: https://docs.mongodb.com/manual/reference/mongodb-extended-json
  data: BSON.EJSON.stringify(
                             {
                               "status": "open",
                               "productIds": productIds,
                               "quantities": quantityValues,
                               "prices": priceValues
                             }
                             ),
  success: () => {
    window.location.href = '/confirmation';
  },
  error: (req, status, message) => {
    //alert("Error: " + message);
    window.location.href = '/cart?message=' + message;
  }
  });
}

function processOrder2() {

  console.log(orderId.value);
  // Update the status to "awaiting confirmation"?
  $.ajax({
  type:'PATCH',
    contentType : 'application/json',
  url:'/api/mongo/orders/' + orderId.value + '/updateStatus',
    // Serialize request data to extended JSON. We use extended JSON
    // both here, and for serializing/deserializing request data on
    // the backend, in order to ensure all MongoDB type information
    // is preserved.
    // See: https://docs.mongodb.com/manual/reference/mongodb-extended-json
  data: BSON.EJSON.stringify(
                             {
                               "status": "submitted",
                             }
                             ),
  success: () => {
    window.location.href = "/" +orderId.value + '/submitted';
  },
  error: (req, status, message) => {
    //alert("Error: " + message);
    window.location.href = '/cart?message=' + message;
  }
  });
}
