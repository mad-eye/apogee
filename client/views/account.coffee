log = new Logger 'accounts'

getCustomer = ->
  return unless Meteor.user() and Meteor.user().type != 'anonymous'
  Customers.findOne userId:Meteor.userId()
  
Template.subscription.helpers
  customerCards: ->
    getCustomer()?.cards?.data

  customerCard: ->
    getCustomer()?.cards?.data[0]

  availableEnterprisePlans: ->
    plans = []
    for i in [10, 25, 50, 100]
      plans.push {seats:i, cost:100*i}
    return plans

  customerSubscription: ->
    return getCustomer()?.subscription

  hasPlan: ->
    subscription = getCustomer()?.subscription
    return false unless subscription
    #TODO: Check for right type of plan at subscription.plan.id
    return subscription.quantity == this.seats

  buttonMessage: ->
    #TODO: Have upgrade/downgrade messages
    return "Subscribe"

Template.subscription.events
  'click button.subscribe-button' : (e, tmpl) ->
    order =
      quantity: parseInt e.target.dataset.seats, 10
      plan: 'self-hosted'
    
    log.debug "Selected #{order.quantity} seats"

    #do we have a card already?
    if getCustomer()?.cards?.data?.length
      Session.set "working", true
      Meteor.call 'submitOrder', order, (err) ->
        Session.set 'working', false
        return log.error err if err
        log.info 'Order submitted'
    else
      token = (res) ->
        order.card = res.id
        log.debug "Submitting order", order
        Session.set "working", true
        Meteor.call 'submitOrder', order, (err) ->
          Session.set 'working', false
          return log.error err if err
          log.info 'Order submitted'
      StripeCheckout.open
        key:         Meteor.settings.public.stripePublicKey
        address:     true
        amount:      10000 * order.quantity
        currency:    'usd'
        name:        'MadEye'
        image:       '/images/madeye_logo_128.png'
        description: "Self-Hosted MadEye License (#{order.quantity} seats) "
        panelLabel:  'Checkout'
        token:       token

    e.preventDefault()
    e.stopPropagation()
    return

  'click #unsubscribe' : (e, tmpl) ->
    log.debug "Unsubscribing"
    if confirm "Are you sure you want to cancel your subscription?"
      Session.set 'working', true
      Meteor.call 'cancelSubscription', (err) ->
        Session.set 'working', false
        return log.error err if err
        log.info 'Subscription cancelled'
    e.preventDefault()
    e.stopPropagation()
    return

  'click #addCard' : (e, tmpl) ->
    log.debug "Adding card"

    Session.set 'working', true
    token = (res) ->
      card = res.id
      log.debug "Submitting new card", card
      Meteor.call 'addCard', card, (err) ->
        Session.set 'working', false
        return log.error err if err
        log.info 'Card added'
    StripeCheckout.open
      key:         Meteor.settings.public.stripePublicKey
      address:     true
      name:        'MadEye'
      image:       '/images/madeye_logo_128.png'
      description: "Add credit card"
      panelLabel:  'Add'
      token:       token

    e.preventDefault()
    e.stopPropagation()
    return

  'click #deleteCard' : (e, tmpl) ->
    log.debug "Deleting card"
    message = "Are you sure you want to delete your card?  " +
      "Your subscription will not renew unless you add a new card."
    if confirm message
      Session.set 'working', true
      Meteor.call 'deleteCard', (err) ->
        Session.set 'working', false
        return log.error err if err
        log.info 'Card deleted'
    e.preventDefault()
    e.stopPropagation()
    return


