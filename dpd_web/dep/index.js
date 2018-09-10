
"use strict";

const autocompleteURL = "https://rest-dev.hres.ca/dpd/dpd_lookup";
const autocompleteLimit = 20;
var resultPageURL = "results.html";
const illegal = ["of", "&", "and", "?", "!", "or", "+", "-", "no."];

$(document).ready(() => {

  if (document.documentElement.lang == "fr") resultPageURL = "results-fr.html";

  $.get("https://rest-dev.hres.ca/dpd/dpd_search?select=drug_product&limit=1", (res) => {

    $("#refresh").text(makeDate(res[0].drug_product.last_refresh));
  });

  new autoComplete({
    selector: "#search",
    minChars: 2,
    source: (term, suggest) => {
      term = term.toLowerCase();

      $.get(getTermQuery(term), (data) => {

        var keywords = $.map(data, (obj) => {

          if (document.documentElement.lang == "fr") {
            return [obj.ingredient + " (ingrédient)", obj.company_name + " (entreprise)", obj.brand_name + " (marque)"];
          }
          else {
            return [obj.ingredient + " (ingredient)", obj.company_name + " (company)", obj.brand_name + " (brand)"];
          }
        });

        var suggestions = [];

        keywords.forEach((keyword) => {
          if (keyword.toLowerCase().indexOf(term) > -1) {
            const pushKeyword = keyword.toLowerCase()
            if (!suggestions.includes(pushKeyword)) suggestions.push(pushKeyword);
          }
        });

        suggest(suggestions);
      });
    }
  })
});

function getTermQuery(term) {

  return autocompleteURL + "?or=(or(brand_name.ilike." + term + "*,company_name.ilike." + term + "*),ingredient.ilike." + term + "*)&limit=" + autocompleteLimit;
}

function passRequest() {

  var string = $("#search").val();
  var search = string.split(" ");

  illegal.forEach((def) => {

    const i = $.inArray(def, search);

    if (i > -1) search.splice(i, 1);
  });

  if (search.length > 0) {
    window.location.href = resultPageURL + "?q=" + search.join("%20");
  }
}

function makeDate(iso) {

  const d = new Date(iso);
  const month = d.getMonth() < 9 ? "0" + (d.getMonth() + 1) : (d.getMonth() + 1);
  const day = d.getDate() < 10 ? "0" + d.getDate() : d.getDate()

  return d.getFullYear() + "-" + month + "-" + day;
}
