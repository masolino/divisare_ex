function onboardingForm() {
  const stripeKey = document.querySelector("#stripe-key");
  if (!!!stripeKey) {
    return;
  }

  const apiKey = stripeKey.getAttribute("data-stripe");
  const stripe = Stripe(apiKey);

  let elements;
  let emailAddress = "";
  let customerName = "";

  initializePaymentForm();
  checkStatus();

  async function initializePaymentForm() {
    let paymentForm = document.querySelector("#payment-form");

    if (!!paymentForm) {
      paymentForm.addEventListener("submit", handleSubmit);
    } else {
      return;
    }
    const options = {
      mode: "subscription",
      amount: 7500,
      currency: "eur",
      paymentMethodTypes: ["paypal", "card", "link", "sepa_debit"],
      appearance: {
        theme: "stripe",
      },
    };

    elements = stripe.elements(options);

    const customerNameField = document.querySelector("#payment-form_name");
    customerNameField.addEventListener("change", (event) => {
      customerName = event.target.value;
    });

    const linkAuthenticationElement = elements.create("linkAuthentication");
    linkAuthenticationElement.mount("#link-authentication-element");
    linkAuthenticationElement.on("change", (event) => {
      emailAddress = event.value.email;
    });

    const paymentElementOptions = {
      layout: "tabs",
    };
    const paymentElement = elements.create("payment", paymentElementOptions);
    paymentElement.mount("#payment-element");
  }

  async function handleSubmit(e) {
    cleanupError();
    e.preventDefault();
    setLoading(true);

    const { error: submitError } = await elements.submit();

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    const priceId = document.querySelector("#price_id").value;

    if (submitError) {
      handleError(submitError);
      setLoading(false);
      return;
    }

    const res = await fetch("/onboarding", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: emailAddress,
        price_id: priceId,
        name: customerName,
        _csrf_token: csrfToken,
      }),
    });

    const data = await res.json();
    const { type, client_secret, redirect } = data;

    if (redirect) {
      return window.location.replace(`${window.location.origin}/subscription`);
    }

    const confirmIntent =
      type === "setup" ? stripe.confirmSetup : stripe.confirmPayment;

    const { error } = await confirmIntent({
      elements,
      clientSecret: client_secret,
      confirmParams: {
        return_url: `${window.location.origin}/onboarding/confirm?email=${encodeURIComponent(emailAddress)}&name=${customerName}`,
        receipt_email: emailAddress,
      },
    });

    if (error.type === "card_error" || error.type === "validation_error") {
      showMessage(error.message);
    } else {
      showMessage("An unexpected error occurred: " + error.message);
    }

    setLoading(false);
  }

  async function checkStatus() {
    const clientSecret = new URLSearchParams(window.location.search).get(
      "payment_intent_client_secret",
    );

    if (!clientSecret) {
      return;
    }

    const { paymentIntent } = await stripe.retrievePaymentIntent(clientSecret);

    switch (paymentIntent.status) {
      case "succeeded":
        showMessage(
          "Payment succeeded! You should have received an email to complete your profile.",
        );
        redirectToConfirmation();
        break;
      case "processing":
        showMessage(
          "Your payment is still processing, but you can already use your account unless payment will fail.",
        );
        redirectToConfirmation();
        break;
      case "requires_payment_method":
        showMessage("Your payment was not successful, please try again.");
        break;
      default:
        showMessage("Something went wrong: " + paymentIntent.status);
        break;
    }
  }

  function handleError(error) {
    const submitBtn = document.querySelector("#submit");
    const messageContainer = document.querySelector("#payment-message");
    messageContainer.textContent = error.message;
    submitBtn.disabled = false;
  }

  function cleanupError() {
    const messageContainer = document.querySelector("#payment-message");
    messageContainer.textContent = "";
  }

  function showMessage(messageText) {
    const messageContainer = document.querySelector("#payment-message");
    if (!!!messageContainer) return;

    messageContainer.classList.remove("hide");
    messageContainer.textContent = messageText;
  }

  function redirectToConfirmation() {
    const messageContainer = document.querySelector("#payment-message");
    if (!!!messageContainer) return;

    const main_app_host = messageContainer.getAttribute("data-redirect-host");

    setTimeout(() => {
      window.location.replace(
        main_app_host +
        "/people/confirmation?confirmation_token=" +
        messageContainer.dataset.confirmationToken,
      );
    }, 3000);
  }

  function setLoading(isLoading) {
    const submitBtn = document.querySelector("#submit");
    const spinner = document.querySelector("#spinner");
    const buttonText = document.querySelector("#button-text");

    submitBtn.disabled = isLoading;
    spinner.classList.toggle("hide", !isLoading);
    buttonText.classList.toggle("hide", isLoading);
  }
}

onboardingForm();
