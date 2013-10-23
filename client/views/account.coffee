log = new MadEye.Logger 'accounts'

Template.payment.events
  'click #customButton' : (e, tmpl) ->
    form = tmpl.find '#enterpriseSubscription'
    order = serializeForm form
    order.quantity = quantity = parseInt order.quantity, 10
    log.debug "Selected #{quantity} seats"
    token = (res) ->
      order.token = res.id
      log.debug "Submitting order", order
      Meteor.call 'submitOrder', order, (err, res) ->
        return log.error err if err
        log.info 'Order submitted:', res


    StripeCheckout.open
      key:         Meteor.settings.public.stripePublicKey
      address:     true
      amount:      10000 * quantity
      currency:    'usd'
      name:        'MadEye'
      description: "Enterprise Edition (#{quantity} seats) "
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


