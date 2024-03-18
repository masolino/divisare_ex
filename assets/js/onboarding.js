function initializeStripe() {
  const stripe = Stripe('pk_test_XL8zlPWp169aVSyuB8HF9ABq00qFjFrupo')

  let elements
  let emailAddress = ''

  initializeNoIntent()
  checkStatus()

  async function initializeNoIntent() {
    let paymentForm = document.querySelector('#payment-form')

    if (!!paymentForm) {
      paymentForm.addEventListener('submit', handleSubmit)
    } else {
      return
    }
    const options = {
      mode: 'subscription',
      amount: 7500,
      currency: 'eur',
      paymentMethodTypes: ['paypal', 'card', 'link', 'sepa_debit'],
      appearance: {
        theme: 'stripe',
      },
    }

    elements = stripe.elements(options)
    const linkAuthenticationElement = elements.create('linkAuthentication')
    linkAuthenticationElement.mount('#link-authentication-element')
    linkAuthenticationElement.on('change', (event) => {
      emailAddress = event.value.email
    })

    const paymentElementOptions = {
      layout: 'tabs',
    }
    const paymentElement = elements.create('payment', paymentElementOptions)
    paymentElement.mount('#payment-element')
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)

    const { error: submitError } = await elements.submit()

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    if (submitError) {
      handleError(submitError)
      return
    }

    const res = await fetch('/onboarding', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: emailAddress,
        price_id: 'price_1Nt41dCoZsrgQwX9RcL1ILpJ',
        _csrf_token: csrfToken,
      }),
    })

    const data = await res.json()
    const { type, client_secret } = data
    const confirmIntent =
      type === 'setup' ? stripe.confirmSetup : stripe.confirmPayment

    const { error } = await confirmIntent({
      elements,
      clientSecret: client_secret,
      confirmParams: {
        return_url: `${window.location.origin}/onboarding/confirm/${emailAddress}`,
        receipt_email: emailAddress,
      },
    })

    if (error.type === 'card_error' || error.type === 'validation_error') {
      showMessage(error.message)
    } else {
      showMessage('An unexpected error occurred.')
    }

    setLoading(false)
  }

  async function checkStatus() {
    const clientSecret = new URLSearchParams(window.location.search).get(
      'payment_intent_client_secret',
    )

    if (!clientSecret) {
      return
    }

    const { paymentIntent } = await stripe.retrievePaymentIntent(clientSecret)

    switch (paymentIntent.status) {
      case 'succeeded':
        showMessage('Payment succeeded!')
        break
      case 'processing':
        showMessage('Your payment is processing.')
        break
      case 'requires_payment_method':
        showMessage('Your payment was not successful, please try again.')
        break
      default:
        showMessage('Something went wrong: ' + paymentIntent.status)
        break
    }
  }

  function handleError(error) {
    const submitBtn = document.querySelector('#submit')
    const messageContainer = document.querySelector('#payment-message')
    messageContainer.textContent = error.message
    submitBtn.disabled = false
  }

  function showMessage(messageText) {
    const messageContainer = document.querySelector('#payment-message')

    if (!!!messageContainer) return

    messageContainer.classList.remove('hidden')
    messageContainer.textContent = messageText

    setTimeout(() => {
      messageContainer.classList.add('hidden')
      messageContainer.textContent = ''
    }, 4000)
  }

  function setLoading(isLoading) {
    const submitBtn = document.querySelector('#submit')
    const spinner = document.querySelector('#spinner')
    const buttonText = document.querySelector('#button-text')

    submitBtn.disabled = isLoading
    spinner.classList.toggle('hidden', !isLoading)
    buttonText.classList.toggle('hidden', isLoading)
  }
}

initializeStripe()
