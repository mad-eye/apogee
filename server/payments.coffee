log = new MadEye.Logger 'payments'

Meteor.publish 'customers', ->
  Customers.find(userId:@userId)

stripe = new Stripe Meteor.settings.stripeSecretKey

Meteor.methods
  submitOrder: (order) ->
    user = getUser @userId
    log.info "Submitting order for #{user.email}:", order
    #TODO: Check for existing cusomer/plan
    customer = Customers.findOne userId: @userId
    if customer
      subscription = stripe.updateSubscription customer.id, order
      customer.subscription = subscription
      customer.save()
      log.info "Updated customer #{customer.id} subscription to", subscription.quantity
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

  cancelSubscription: ->
    log.info "Cancelling subscription for #{@userId}"
    customer = Customers.findOne userId: @userId
    unless customer
      throw new Meteor.Error 401, 'CustomerNotFound', "No customer to cancel subscription of."
    response = stripe.cancelSubscription customer.id
    log.trace "cancelSubscription response:", response
    delete customer.subscription
    customer.save()

    return



getUser = (userId) ->
  if userId
    user = Meteor.users.findOne userId
  if !user or user.type == 'anonymous'
    throw new Meteor.Error 401, 'Authentication', 'You must be logged in to submit an order'
  return user

