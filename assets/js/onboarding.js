function onboardingForm() {
  const stripeKey = document.querySelector("#stripe-key");
  if (!!!stripeKey) {
    return;
  }

  const apiKey = stripeKey.getAttribute("data-stripe");
  const stripe = Stripe(apiKey);

  let elements;
  let emailAddress = "";

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
    e.preventDefault();
    setLoading(true);

    const { error: submitError } = await elements.submit();

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    if (submitError) {
      handleError(submitError);
      return;
    }

    const res = await fetch("/onboarding", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: emailAddress,
        price_id: "price_1Nt41dCoZsrgQwX9RcL1ILpJ",
        _csrf_token: csrfToken,
      }),
    });

    const data = await res.json();
    const { type, client_secret } = data;
    const confirmIntent =
      type === "setup" ? stripe.confirmSetup : stripe.confirmPayment;

    const { error } = await confirmIntent({
      elements,
      clientSecret: client_secret,
      confirmParams: {
        return_url: `${window.location.origin}/onboarding/confirm/${emailAddress}`,
        receipt_email: emailAddress,
      },
    });

    if (error.type === "card_error" || error.type === "validation_error") {
      showMessage(error.message);
    } else {
      showMessage("An unexpected error occurred.");
    }

    setLoading(false);
  }

  async function checkStatus() {
    const clientSecret = new URLSearchParams(window.location.search).get(
      "payment_intent_client_secret"
    );

    if (!clientSecret) {
      return;
    }

    const { paymentIntent } = await stripe.retrievePaymentIntent(clientSecret);

    switch (paymentIntent.status) {
      case "succeeded":
        showMessage("Payment succeeded!");
        redirectToConfirmation();
        break;
      case "processing":
        showMessage("Your payment is processing.");
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

  function showMessage(messageText) {
    const messageContainer = document.querySelector("#payment-message");
    if (!!!messageContainer) return;

    messageContainer.classList.remove("hidden");
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
          messageContainer.dataset.confirmationToken
      );
    }, 3000);
  }

  function setLoading(isLoading) {
    const submitBtn = document.querySelector("#submit");
    const spinner = document.querySelector("#spinner");
    const buttonText = document.querySelector("#button-text");

    submitBtn.disabled = isLoading;
    spinner.classList.toggle("hidden", !isLoading);
    buttonText.classList.toggle("hidden", isLoading);
  }
}

function billingForm() {
  const mainForm = document.querySelector("#billing-form");
  let isEu = false;
  let isIta = false;

  if (!!!mainForm) {
    return;
  }

  const countryCodes = document.querySelector("#billing-form_country_code");
  const stateCodes = document.querySelector("#billing-form_state_code");
  const stateCodesOpts = JSON.parse(stateCodes.getAttribute("data-opts"));
  const euCountries = JSON.parse(
    countryCodes.getAttribute("data-eu-countries")
  );

  const isBusiness = document.querySelector("#billing-form_business");
  const isBusinessLabel = isBusiness.closest("label");

  const businessForm = document.querySelector("#business-form");
  const italianForm = document.querySelector("#italian-form");
  const italianBusinessForm = document.querySelector("#ita-business-form");

  loadStateCodesOpts(countryCodes.value);

  // show business checkbox if country is in EU
  toggleForm(isEu, isBusinessLabel);
  toggleForm(isEu && isBusiness.checked, businessForm);
  // toggle italian fields for italian non-business
  toggleForm(isIta && !isBusiness.checked, italianForm);
  // toggle italian fields for italian business
  toggleForm(isIta && isBusiness.checked, italianBusinessForm);

  countryCodes.addEventListener("change", (e) => {
    isEu = euCountries.includes(e.target.value);
    isIta = e.target.value === "IT";

    loadStateCodesOpts(e.target.value);
    toggleForm(isEu, isBusinessLabel);
    toggleForm(isIta && !isBusiness.checked, italianForm);
    toggleForm(isIta && isBusiness.checked, italianBusinessForm);
  });

  stateCodes.addEventListener("change", (e) => {
    console.log("STATE CODE", e.target.value);
  });

  isBusiness.addEventListener("change", (e) => {
    toggleForm(isEu && isBusiness.checked, businessForm);
    toggleForm(isIta && isBusiness.checked, italianBusinessForm);
    toggleForm(isIta && !isBusiness.checked, italianForm);
  });

  function loadStateCodesOpts(country) {
    stateCodes.innerText = null;

    stateCodesOpts[country].forEach((state) => {
      let [key, value] = Object.entries(state).flat();
      let option = document.createElement("option");
      option.text = key;
      option.value = value;
      stateCodes.appendChild(option);
    });

    stateCodes.value = stateCodesOpts[country][0].value;
  }

  function toggleForm(condition, form) {
    if (condition) {
      form.classList.remove("hidden");
    } else {
      form.classList.add("hidden");
    }
  }
}

onboardingForm();
billingForm();
