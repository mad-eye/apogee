# These are orders from Stripe
class Order extends MadEye.Model
@Orders = new Meteor.Collection 'orders',
  transform: (doc) ->
    new Order doc
Order.prototype.collection = @Orders

# These are Stripe customer objects, with
# the following fields:
# _id: id of customer object
# userId: _id of corresponding User doc.
class Customer extends MadEye.Model
@Customers = new Meteor.Collection 'customers',
  transform: (doc) ->
    new Customer doc
Customer.prototype.collection = @Customers


