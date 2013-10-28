log = new MadEye.Logger 'accounts'

getCustomer = ->
  return unless Meteor.user() and Meteor.user().type != 'anonymous'
  Customers.findOne userId:Meteor.userId()
  
Template.payment.helpers
  customerCards: ->
    getCustomer()?.cards?.data

  cardDetails: ->
    "#{@type} ending in #{@last4}, expiring #{@exp_month}/#{@exp_year}"

  availableEnterprisePlans: ->
    plans = []
    for i in [10, 25, 50, 100]
      plans.push {seats:i, cost:100*i}
    return plans

  hasPlan: ->
    subscription = getCustomer()?.subscription
    return false unless subscription
    #TODO: Check for right type of plan at subscription.plan.id
    return subscription.quantity == this.seats

  buttonMessage: ->
    #TODO: Have upgrade/downgrade messages
    return "Subscribe"

Template.payment.events
  'click button.subscribe-button' : (e, tmpl) ->
    order =
      quantity: parseInt e.target.dataset.seats, 10
      plan: 'enterprise'
    
    log.debug "Selected #{order.quantity} seats"

    #do we have a card already?
    if getCustomer()?.cards?.data?.length
      Meteor.call 'submitOrder', order, (err) ->
        return log.error err if err
        log.info 'Order submitted'
    else
      token = (res) ->
        order.card = res.id
        log.debug "Submitting order", order
        Meteor.call 'submitOrder', order, (err) ->
          return log.error err if err
          log.info 'Order submitted'


      StripeCheckout.open
        key:         Meteor.settings.public.stripePublicKey
        address:     true
        amount:      10000 * order.quantity
        currency:    'usd'
        name:        'MadEye'
        description: "Enterprise Edition (#{order.quantity} seats) "
        panelLabel:  'Checkout'
        token:       token


    e.preventDefault()
    e.stopPropagation()
    return

  'click #unsubscribe' : (e, tmpl) ->
    log.debug "Unsubscribing"
    if confirm "Are you sure you want to cancel your subscription?"
      Meteor.call 'cancelSubscription', (err) ->
        return log.error err if err
        log.info 'Subscription cancelled'
    e.preventDefault()
    e.stopPropagation()
    return

  'click #deleteCard' : (e, tmpl) ->
    log.debug "Deleting card"
    message = "Are you sure you want to delete your card?  " +
      "Your subscription will not renew unless you add a new card."
    if confirm message
      Meteor.call 'deleteCard', (err) ->
        return log.error err if err
        log.info 'Card deleted'
    e.preventDefault()
    e.stopPropagation()
    return

serializeForm = (form, originalVals) ->
  if originalVals
    formVals = _.clone(originalVals)
  else
    formVals = {}
  valArray = $(form).serializeArray()
  _.each valArray, (valObj) ->
    formVals[valObj.name] = valObj.value.trim()
  return formVals


