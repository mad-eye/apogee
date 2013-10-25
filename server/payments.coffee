log = new MadEye.Logger 'payments'

Meteor.publish 'customers', ->
  Customers.find(userId:@userId)

stripe = new Stripe Meteor.settings.stripeSecretKey

Meteor.methods
  submitOrder: (order) ->
    user = Meteor.users.findOne @userId
    if !user or user.type == 'anonymous'
      throw new Meteor.Error 401, 'Authentication', 'You must be logged in to submit an order'
    log.debug "Submitting order for #{user.email}:", order
    #TODO: Check for existing cusomer/plan
    customer = Customers.findOne userId: @userId
    if customer
      if customer.subscription
        if customer.subscription.plan.id == order.plan
          if customer.subscription.quantity == order.quantity
            #TODO: Return warning, nothing changed
          else
            #TODO: Subscribe with new quantity
        else
          #TODO: Change plan
      else
        #TODO: Add subscription
    else
      #Add new customer with plan
      customer =
        card: order.token
        description: "A Customer from Riot Games" #TODO: Fill based on user's company
        email: user.email
        metadata:
          userId: @userId
          company: "Riot Games" #TODO: Fill based on user's company
        plan: order.plan
        quantity: order.quantity
      customer = stripe.createCustomer customer
      customer._id = customer.id
      customer.userId = @userId
      Customers.insert customer
      log.info "Added new customer:", customer

    return



