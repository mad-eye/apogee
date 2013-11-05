Future = Npm.require 'fibers/future'

futureCallback = (future) ->
  return (err, result) ->
    if err
      console.error err
      #TODO: Wrap this so we can handle it better
      future['throw'] err
    else
      future['return'] result

class Stripe
  constructor: (stripeSecretKey) ->
    @stripeClient = Npm.require("stripe")(stripeSecretKey)

  retrieveCustomer: (customerId) ->
    future = new Future()
    @stripeClient.customers.retrieve customerId, futureCallback(future)
    return future.wait()

  createCustomer: (customer) ->
    future = new Future()
    @stripeClient.customers.create customer, futureCallback(future)
    return future.wait()

  updateSubscription: (customerId, subscription) ->
    future = new Future()
    @stripeClient.customers.updateSubscription customerId, subscription, futureCallback(future)
    return future.wait()

  cancelSubscription: (customerId) ->
    future = new Future()
    @stripeClient.customers.cancelSubscription customerId, futureCallback(future)
    return future.wait()

  deleteCard: (customerId, cardId) ->
    future = new Future()
    @stripeClient.customers.deleteCard customerId, cardId, futureCallback(future)
    return future.wait()

  addCard: (customerId, cardToken) ->
    future = new Future()
    @stripeClient.customers.createCard customerId, card:cardToken, futureCallback(future)
    return future.wait()


