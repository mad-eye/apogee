Future = Npm.require 'fibers/future'

class Stripe
  constructor: (stripeSecretKey) ->
    @stripe = Npm.require("stripe")(stripeSecretKey)

  createCustomer: (customer) ->
    future = new Future()
    @stripe.customers.create customer, (err, customer) ->
      if err
        console.error err
        #TODO: Wrap this so we can handle it better
        future['throw'] err
      else
        future['return'] customer
    return future.wait()


