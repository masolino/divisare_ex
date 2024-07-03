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

  const currentCountry = countryCodes.value;

  loadStateCodesOpts(currentCountry);
  stateCodes.value = stateCodes.getAttribute("data-selected");

  updateEuBusiness(currentCountry);

  // show business checkbox if country is in EU
  toggleForm(isEu, isBusinessLabel);
  toggleForm(isEu && isBusiness.checked, businessForm);
  // toggle italian fields for italian non-business
  toggleForm(isIta && !isBusiness.checked, italianForm);
  // toggle italian fields for italian business
  toggleForm(isIta && isBusiness.checked, italianBusinessForm);

  countryCodes.addEventListener("change", (e) => {
    let selectedCountry = e.target.value;
    isEu = euCountries.includes(selectedCountry);
    isIta = selectedCountry === "IT";

    if (!isEu && isBusiness.checked) {
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
    toggleForm(isEu && isBusiness.checked, businessForm);
    toggleForm(isIta && isBusiness.checked, italianBusinessForm);
    toggleForm(isIta && !isBusiness.checked, italianForm);
  });

  function updateEuBusiness(country) {
    isEu = euCountries.includes(country);
    isIta = country === "IT";

    loadStateCodesOpts(country);
    stateCodes.value = stateCodes.getAttribute("data-selected");

    toggleForm(isEu && isBusiness.checked, businessForm);
    toggleForm(isEu, isBusinessLabel);
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

  function toggleForm(condition, form) {
    if (condition) {
      form.classList.remove("hide");
    } else {
      form.classList.add("hide");
    }
  }
}

billingForm();
