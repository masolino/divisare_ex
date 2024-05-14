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
    countryCodes.getAttribute("data-eu-countries"),
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
      form.classList.remove("hide");
    } else {
      form.classList.add("hide");
    }
  }
}

billingForm();
