log = new Logger 'payments'

Meteor.publish 'customers', ->
  Customers.find(userId:@userId)

stripe = new Stripe Meteor.settings.stripeSecretKey

Meteor.methods
  submitOrder: (order) ->
    user = getUser @userId
    log.info "Submitting order for #{user.email}:", order
    customer = Customers.findOne userId: @userId
    if customer
      subscription = stripe.updateSubscription customer.id, order
      customer.subscription = subscription
      customer.save()
      refreshCustomerData userId: @userId, customerId: customer.id
      log.info "Updated customer #{customer.id} subscription to", subscription.quantity
    else
      #Add new customer with plan
      customer =
        card: order.card
        description: "Self-hosted customer" #TODO: Company name?
        email: user.email
        metadata:
          userId: @userId
          licenseKey: Random.id()
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
      throw new Meteor.Error 404, 'CustomerNotFound', "No customer to cancel subscription of."
    response = stripe.cancelSubscription customer.id
    log.trace "cancelSubscription response:", response
    delete customer.subscription
    customer.save()
    refreshCustomerData userId: @userId, customerId: customer.id
    return

  addCard: (card) ->
    log.info "Adding card for #{@userId}"
    customer = Customers.findOne userId: @userId
    unless customer
      throw new Meteor.Error 404, 'CustomerNotFound', "No customer to add card for."
    unless card
      throw new Meteor.Error 404, 'CardNotFound', "No card was found to delete."
    response = stripe.addCard customer.id, card
    log.trace "Add card response:", response
    customer.cards ?= {}
    customer.cards.data ?= []
    customer.cards.data.push response
    customer.save()
    refreshCustomerData userId: @userId, customerId: customer.id
    return

  deleteCard: ->
    log.info "Deleting card for #{@userId}"
    customer = Customers.findOne userId: @userId
    unless customer
      throw new Meteor.Error 404, 'CustomerNotFound', "No customer to delete card from."
    card = customer.cards.data[0]
    unless card
      throw new Meteor.Error 404, 'CardNotFound', "No card was found to delete."
    response = stripe.deleteCard customer.id, card.id
    log.trace "Delete card response:", response
    customer.cards.data.splice(0, 1)
    customer.save()
    refreshCustomerData userId: @userId, customerId: customer.id
    return


getUser = (userId) ->
  if userId
    user = Meteor.users.findOne userId
  if !user or user.type == 'anonymous'
    throw new Meteor.Error 401, 'Authentication', 'You must be logged in to retrieve customer info.'
  return user

#Asynchronously refresh the info
refreshCustomerData = ({userId, customerId}) ->
  unless userId
    throw new Error "userId is required to refresh customer data"
  unless customerId
    throw new Error "customerId is required to refresh customer data"
  Meteor.setTimeout ->
    customer = stripe.retrieveCustomer customerId
    customer._id = customer.id
    customer.userId = userId
    Customers.update customer._id, customer
  , 0
  return


