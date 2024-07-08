function billingForm() {
  const mainForm = document.querySelector("#billing-form");
  if (!!!mainForm) {
    return;
  }

  let isIta = false;
  let formVat = document.querySelector("#billing-form_vat");

  const countryCodes = document.querySelector("#billing-form_country_code");
  const countryVies = JSON.parse(countryCodes.getAttribute("data-vies"));
  const stateCodes = document.querySelector("#billing-form_state_code");
  const stateCodesOpts = JSON.parse(stateCodes.getAttribute("data-subdivisions"));


  const isBusiness = document.querySelector("#billing-form_business");
  const isBusinessLabel = isBusiness.closest("label");

  const businessForm = document.querySelector("#business-form");
  const italianForm = document.querySelector("#italian-form");
  const italianBusinessForm = document.querySelector("#ita-business-form");

  let currentCountry = countryCodes.value;

  stateCodes.value = stateCodes.getAttribute("data-selected");
  autocompleteFormVat(currentCountry, false)

  updateEuBusiness(currentCountry);
  loadStateCodesOpts(currentCountry);

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
    currentCountry = e.target.value;
    isIta = currentCountry === "IT";

    if (!isIta && isBusiness.checked) {
      isBusiness.checked = false;
      businessForm.querySelectorAll("input").forEach((i) => {
        i.value = "";
      });

      italianBusinessForm.querySelectorAll("input").forEach((i) => {
        i.value = "";
      });
    }

    updateEuBusiness(currentCountry);
    autocompleteFormVat(currentCountry, true);
    stateCodes.value = "--";
  });

  isBusiness.addEventListener("change", (e) => {
    autocompleteFormVat(currentCountry, true);
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

  function autocompleteFormVat(countryCode, override) {
    if ((!isIta || (isIta && isBusiness.checked)) && (override || formVat.value.length == 0)) {
      formVat.value = countryVies[countryCode];
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
