function paymentMethodForm() {
  const stripeKey = document.querySelector("#stripe-key");
  const pmForm = document.querySelector("#payment-method-form");

  if (!!!stripeKey) {
    return;
  }

  const apiKey = stripeKey.getAttribute("data-stripe");
  const stripe = Stripe(apiKey);

  let elements;

  initializePaymentMethodForm();
  checkStatus();

  async function initializePaymentMethodForm() {
    if (!!pmForm) {
      pmForm.addEventListener("submit", handleSubmit);
    } else {
      return;
    }

    const secret = pmForm.getAttribute("data-secret");

    const options = {
      clientSecret: secret,
      appearance: {
        theme: "stripe",
      },
    };

    elements = stripe.elements(options);
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

    const { error } = await stripe.confirmSetup({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/payments/complete`,
      },
    });

    if (error) {
      handleError(error);
      setLoading(false);
      return;
    } else {
      // all is ok
    }

    setLoading(false);
  }

  function handleError(error) {
    const submitBtn = document.querySelector("#submit");
    submitBtn.disabled = false;

    showMessage(error.message);
  }

  function cleanupError() {
    const messageContainer = document.querySelector("#message");
    messageContainer.textContent = "";
  }

  function showMessage(messageText) {
    const messageContainer = document.querySelector("#message");
    if (!!!messageContainer) return;

    // messageContainer.classList.remove("hide");
    messageContainer.textContent = messageText;
  }

  function setLoading(isLoading) {
    const submitBtn = document.querySelector("#submit");
    const spinner = document.querySelector("#spinner");
    const buttonText = document.querySelector("#button-text");

    submitBtn.disabled = isLoading;
    spinner.classList.toggle("hide", !isLoading);
    buttonText.classList.toggle("hide", isLoading);
  }

  async function checkStatus() {
    const clientSecret = new URLSearchParams(window.location.search).get(
      "setup_intent_client_secret",
    );

    if (!clientSecret) {
      return;
    }

    stripe.retrieveSetupIntent(clientSecret).then(({ setupIntent }) => {
      switch (setupIntent.status) {
        case "succeeded": {
          showMessage("Success! Your payment method has been saved.");
          break;
        }

        case "processing": {
          showMessage(
            "Processing payment details. We'll update you when processing is complete.",
          );

          break;
        }

        case "requires_payment_method": {
          showMessage(
            "Failed to process payment details. Please try another payment method.",
          );
          break;
        }
      }
    });
  }
}

paymentMethodForm();
