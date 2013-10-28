Future = Npm.require 'fibers/future'

futureCallback = (future) ->
  return (err, result) ->
    if err
      #TODO: Wrap this so we can handle it better
      future['throw'] err
    else
      future['return'] result

class Stripe
  constructor: (stripeSecretKey) ->
    @stripe = Npm.require("stripe")(stripeSecretKey)

  createCustomer: (customer) ->
    future = new Future()
    @stripe.customers.create customer, futureCallback(future)
    return future.wait()

  updateSubscription: (customerId, subscription) ->
    future = new Future()
    @stripe.customers.updateSubscription customerId, subscription, futureCallback(future)
    return future.wait()

  cancelSubscription: (customerId) ->
    future = new Future()
    @stripe.customers.cancelSubscription customerId, futureCallback(future)
    return future.wait()



