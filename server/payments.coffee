log = new MadEye.Logger 'payments'

Orders = new Meteor.Collection 'orders'
Customers = new Meteor.Collection 'customers'

stripe = new Stripe Meteor.settings.stripeSecretKey

Meteor.methods
  submitOrder: (order) ->
    user = Meteor.users.findOne @userId
    if !user or user.type == 'anonymous'
      #TODO: Throw a more complete error
      throw new Meteor.Error 'You must be logged in to submit an order'
    log.debug "Submitting order for #{user.email}:", order
    if user.enterpriseSubscription
      #TODO: Need up update subscription
      log.error "Update subscription not yet implemented"
      throw new Meteor.Error "Update subscription not yet implemented"
    else
      customer =
        card: order.token
        description: "A Customer from Riot Games" #TODO: Fill based on user's company
        email: user.email
        metadata:
          userId: @userId
          company: "Riot Games" #TODO: Fill based on user's company
        plan: order.plan
        quantity: order.quantity
      returnedCustomer = stripe.createCustomer customer
      Customers.insert returnedCustomer
      console.log "inserted customer:", returnedCustomer
      return



