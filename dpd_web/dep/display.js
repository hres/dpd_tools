
const drugCode = window.location.search.substr(4);
const documentURL = "https://rest-dev.hres.ca/dpd/dpd_json";
const monographURL = "https://rest-dev.hres.ca/rest-dev/product_monographs";

$(document).ready(() => {

  const url = documentURL + "?select=*&drug_code=eq." + drugCode;

  $.get(url, (data) => {

    const drug = data[0].drug_product;

    $("#product-title").html(drug.brand_name);

    const status = drug.status_detail[0];

    var statusDate = "N/A";
    var marketDate = "N/A";

    if (status.history_date) statusDate = makeDate(status.history_date);
    if (status.original_market_date) marketDate = makeDate(status.original_market_date);

    $("#status-date").html(statusDate);
    $("#market").html(marketDate);
    $("#product").html(drug.brand_name);
    $("#din").html(drug.drug_identification_number);
    $("#company").html("<strong>" + drug.company.company_name + "</strong>");
    $("#active").html(drug.number_of_ais);

    if (drug.therapeutic_class) {
			$("#ahfs").html(drug.therapeutic_class[0].tc_ahfs_number + " " + drug.therapeutic_class[0].tc_ahfs);
			$("#atc").html(drug.therapeutic_class[0].tc_atc_number + " " + drug.therapeutic_class[0].tc_atc);
		}

		$("#aig").html(drug.ai_group_no);

    var body = "";

    if (document.documentElement.lang == "fr") { // FRENCH
      $("#company").append("<br>" + drug.company.street_name + "<br>" + drug.company.city_name + ", " + drug.company.province_f + "<br>" + drug.company.country_f + " " + drug.company.postal_code);
      $("#drug-class").html(drug.class_f);
      $("#dosage").html(drug.dosage_form_f[0]);
      $("#route").html(drug.route_f[0]);

      if (drug.schedule) $("#schedule").html(drug.schedule_f[0]);

      (drug.active_ingredients_detail).forEach((ing) => {

        body += "<tr>" +
          "<td>" + ing.ingredient_f + "</td>" +
          "<td>" + ing.strength + " " + ing.strength_unit_f + "</td>" +
          "</tr>";
      });

      $("#status").html("<strong>" + status.status_f + "</strong>");
      $("#rmp").html("Un Plan de Gestion des Risques (PGR) pour ce produit " + (drug.risk_man_plan == "N" ? "n'a pas été" : "a été") + " soumis.");

      if (drug.product_monograph_fr_url) {
        $("#monograph").html("<a href='" + drug.product_monograph_fr_url + "' target='_blank'>Monographie électronique (" + makeDate(drug.pm_date) + ")</a>");
      }
      else {
        $("#monograph").html("Aucune monographie électronique disponible");
      }
    }
    else { // ENGLISH
      $("#company").append("<br>" + drug.company.street_name + "<br>" + drug.company.city_name + ", " + drug.company.province + "<br>" + drug.company.country + " " + drug.company.postal_code);
      $("#drug-class").html(drug.class);
      $("#dosage").html(drug.dosage_form[0]);
      $("#route").html(drug.route[0]);

      if (drug.schedule) $("#schedule").html(drug.schedule[0]);

      (drug.active_ingredients_detail).forEach((ing) => {

        body += "<tr>" +
          "<td>" + ing.ingredient + "</td>" +
          "<td>" + ing.strength + " " + ing.strength_unit + "</td>" +
          "</tr>";
      });

      $("#status").html("<strong>" + status.status + "</strong>");
      $("#rmp").html("A Risk Management Plan (RMP) for this product " + (drug.risk_man_plan == "N" ? "was not" : "was") + " submitted.");

      if (drug.product_monograph_en_url) {
        $("#monograph").html("<a href='" + drug.product_monograph_en_url + "' target='_blank'>Electronic Monograph (" + makeDate(drug.pm_date) + ")</a>");
      }
      else {
        $("#monograph").html("No Electronic Monograph Available");
      }
    }

    $("#ingredients-content").html(body);

    if (drug.vet_species) {
			for (var i = 0; i < drug.vet_species.length; i++) {
				if (i == 0) {
					$("#species").html(drug.vet_species[i]);
				}
				else {
					$("#species").append(", " + drug.vet_species[i]);
				}
			}

			$("#species-div").css("display", "block");
		}

    $("#api-call").attr("href", url).attr("target", "_blank").html(url);
    $("#refresh").text(makeDate(drug.last_refresh));
  });
});

function makeDate(iso) {

  const d = new Date(iso);
  const month = d.getMonth() < 9 ? "0" + (d.getMonth() + 1) : (d.getMonth() + 1);
  const day = d.getDate() < 10 ? "0" + d.getDate() : d.getDate()

  return d.getFullYear() + "-" + month + "-" + day;
}
