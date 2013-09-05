Template.payment.rendered = ->
  token = (res)->
    $input = $('<input type=hidden name=stripeToken />').val(res.id)
    $('form').append($input).submit()

  StripeCheckout.open
    key:         'pk_test_W14Iel8M8FHveAP3mw5Y94Se'
    address:     true
    amount:      49500
    currency:    'usd'
    name:        'MadEye'
    description: 'Enterprise Edition (1st Month) '
    panelLabel:  'Checkout'
    token:       token

  false
