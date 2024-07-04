function billingForm() {
  const mainForm = document.querySelector("#billing-form");
  if (!!!mainForm) {
    return;
  }

  let isIta = false;
  let formVat = document.querySelector("#billing-form_vat");

  const countryCodes = document.querySelector("#billing-form_country_code");
  const stateCodes = document.querySelector("#billing-form_state_code");
  const stateCodesOpts = JSON.parse(stateCodes.getAttribute("data-opts"));

  const isBusiness = document.querySelector("#billing-form_business");
  const isBusinessLabel = isBusiness.closest("label");

  const businessForm = document.querySelector("#business-form");
  const italianForm = document.querySelector("#italian-form");
  const italianBusinessForm = document.querySelector("#ita-business-form");

  const currentCountry = countryCodes.value;

  autocompleteFormVat(currentCountry)

  loadStateCodesOpts(currentCountry);
  stateCodes.value = stateCodes.getAttribute("data-selected");

  updateEuBusiness(currentCountry);

  // show business checkbox if country is Italy
  toggleForm(isIta, isBusinessLabel);
  toggleForm(!isIta || (isIta && isBusiness.checked), businessForm);
  // toggle business checkbox for italians
  toggleForm(isIta, isBusiness);
  // toggle italian fields for italian non-business
  toggleForm(isIta && !isBusiness.checked, italianForm);
  // toggle italian fields for italian business
  toggleForm(isIta && isBusiness.checked, italianBusinessForm);

  countryCodes.addEventListener("change", (e) => {
    let selectedCountry = e.target.value;
    isIta = selectedCountry === "IT";

    autocompleteFormVat(selectedCountry)

    if (!isIta && isBusiness.checked) {
      isBusiness.checked = false;
      businessForm.querySelectorAll("input").forEach((i) => {
        i.value = "";
      });

      italianBusinessForm.querySelectorAll("input").forEach((i) => {
        i.value = "";
      });
    }

    updateEuBusiness(selectedCountry);
    stateCodes.value = "--";
  });

  isBusiness.addEventListener("change", (e) => {
    toggleForm(!isIta || (isIta && isBusiness.checked), businessForm);
    toggleForm(isIta && isBusiness.checked, italianBusinessForm);
    toggleForm(isIta && !isBusiness.checked, italianForm);
  });

  function updateEuBusiness(country) {
    isIta = country === "IT";

    loadStateCodesOpts(country);
    stateCodes.value = stateCodes.getAttribute("data-selected");

    toggleForm(!isIta || (isIta && isBusiness.checked), businessForm);
    toggleForm(isIta, isBusinessLabel);
    toggleForm(isIta, isBusiness);
    toggleForm(isIta && !isBusiness.checked, italianForm);
    toggleForm(isIta && isBusiness.checked, italianBusinessForm);
  }

  function loadStateCodesOpts(country) {
    stateCodes.innerText = null;

    stateCodesOpts[country].forEach((state) => {
      let [key, _value] = Object.entries(state).flat();
      let option = document.createElement("option");
      option.text = key;
      option.value = key;
      stateCodes.appendChild(option);
    });
  }

  function autocompleteFormVat(countryCode) {
    if (!isIta || (isIta && isBusiness.checked)) {
      formVat.value = countryCode;
    }
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
