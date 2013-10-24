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
    plan = getCustomer()?.subscription?.plan?
    return false unless plan
    return getCustomer().subscription.quantity == this.seats

  buttonMessage: ->
    #TODO: Have upgrade/downgrade messages
    return "Subscribe"

Template.payment.events
  'click button.subscribe-button' : (e, tmpl) ->
    order =
      quantity: parseInt e.target.dataset.seats, 10
      plan: 'enterprise'
    
    log.debug "Selected #{order.quantity} seats"
    token = (res) ->
      order.token = res.id
      log.debug "Submitting order", order
      Meteor.call 'submitOrder', order, (err, res) ->
        return log.error err if err
        log.info 'Order submitted:', res


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

serializeForm = (form, originalVals) ->
  if originalVals
    formVals = _.clone(originalVals)
  else
    formVals = {}
  valArray = $(form).serializeArray()
  _.each valArray, (valObj) ->
    formVals[valObj.name] = valObj.value.trim()
  return formVals


