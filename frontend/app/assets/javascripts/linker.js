//= require jquery.tokeninput

$(function() {
  $.fn.linker = function() {
    $(this).each(function() {
      var $this = $(this);
      var $linkerWrapper = $this.parents(".linker-wrapper:first");

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var config = {
        url: $this.data("url"),
        browse_url: $this.data("browse-url"),
        format_template: $this.data("format_template"),
        format_template_id: $this.data("format_template_id"),
        format_property: $this.data("format_property"),
        path: $this.data("path"),
        name: $this.data("name"),
        multiplicity: $this.data("multiplicity") || "many",
        label: $this.data("label"),
        label_plural: $this.data("label_plural"),
        modal_id: $this.data("modal_id") || ($this.attr("id") + "_modal"),
        sortable: $this.data("sortable") === true,
        types: $this.data("types"),
        exclude_ids: $this.data("exclude") || []
      };

      if (config.format_template && config.format_template.substring(0,2) != "${") {
        config.format_template = "${" + config.format_template + "}";
      }

      var renderItemsInModal = function(page) {
        var currentlySelectedIds = [];
        $.each($this.tokenInput("get"), function() {currentlySelectedIds.push(this.id);});

        $.ajax({
          url: config.browse_url,
          data: {
            page: 1,
            type: config.types,
            linker: true,
            exclude: config.exclude_ids
          },
          type: "GET",
          dataType: "html",
          success: function(html) {
            var $modal = $("#"+config.modal_id);

            var $linkerBrowseContainer = $(".linker-container", $modal);

            var initBrowseFormInputs = function() {
              // add some click handlers to allow clicking of the row
              $(":input[name=linker-item]", $linkerBrowseContainer).each(function() {
                var $input = $(this);
                $input.click(function(event) {
                  event.stopPropagation();

                  // reset the currentlySelectedIds so pagination stays in sync
                  currentlySelectedIds = [$input.val()];

                  $("tr.selected", $input.closest("table")).removeClass("selected");
                  $input.closest("tr").addClass("selected");
                });

                $("td", $input.closest("tr")).click(function(event) {
                  event.preventDefault();

                  $input.trigger("click");
                });
              });

              // select a radio is it's currently a selected record
              if (currentlySelectedIds.length > 0) {
                $.each(currentlySelectedIds, function() {
                  $(":input[value='"+this+"']", $linkerBrowseContainer).trigger("click");
                });
              }

              $modal.trigger("resize");
            };

            $linkerBrowseContainer.html(html);
            $($linkerBrowseContainer).on("click", "a", function(event) {
              event.preventDefault();

              $linkerBrowseContainer.load(event.target.href, initBrowseFormInputs);
            });

            $($linkerBrowseContainer).on("submit", "form", function(event) {
              event.preventDefault();

              var $form = $(event.target);

              $linkerBrowseContainer.load($form.attr("action")+".js?" + $(event.target).serialize(), initBrowseFormInputs);
            });

            $(":input:visible:first", $linkerBrowseContainer).focus();

            initBrowseFormInputs();
          }
        });
      };


      var renderCreateFormForObject = function(form_uri) {
        var $modal = $("#"+config.modal_id);

        var initCreateForm = function(formEl) {
          $(".linker-container", $modal).html(formEl);
          $("#createAndLinkButton", $modal).removeAttr("disabled");
          $("form", $modal).ajaxForm({
            data: {
              inline: true
            },
            beforeSubmit: function() {
              $("#createAndLinkButton", $modal).attr("disabled","disabled");
            },
            success: function(response, status, xhr) {
              if ($(response).is("form")) {
                initCreateForm(response);
              } else {
                if (config.multiplicity === "one") {
                  clearTokens();
                }

                $this.tokenInput("add", {
                  id: response.uri,
                  name: response.title,
                  json: response
                });
                $this.triggerHandler("change");
                $modal.modal("hide");
              }
            },
            error: function(obj, errorText, errorDesc) {
              $("#createAndLinkButton", $modal).removeAttr("disabled");
            }
          });
          $modal.trigger("resize");
          $(document).triggerHandler("loadedrecordform.aspace", [$modal]);
          $(":input:visible:first", $modal).focus();
        };

        $.ajax({
          url: form_uri,
          success: initCreateForm
        });
        $("#createAndLinkButton", $modal).click(function() {
          $("form", $modal).triggerHandler("submit");
        });
      };


      var showLinkerCreateModal = function() {
        AS.openCustomModal(config.modal_id, "Create "+ config.label, AS.renderTemplate("linker_createmodal_template", config), 'container');
        if ($(this).hasClass("linker-create-btn")) {
          renderCreateFormForObject($(this).data("target"));
        } else {
          renderCreateFormForObject($(".linker-create-btn:first", $linkerWrapper).data("target"));
        }
        return false; // IE8 patch
      };


      var addSelected = function() {
        selectedItems  = [];
        $(".token-input-delete-token", $linkerWrapper).each(function() {
          $(this).triggerHandler("click");
        });
        $(".linker-container :input:checked", "#"+config.modal_id).each(function() {
          var item = $(this).data("object");
          $this.tokenInput("add", {
            id: $(this).val(),
            name: item.title,
            json: item
          });
        });
        $("#"+config.modal_id).modal('hide');
        $this.triggerHandler("change");
      };


      var showLinkerBrowseModal = function() {
        AS.openCustomModal(config.modal_id, "Browse "+ config.label_plural, AS.renderTemplate("linker_browsemodal_template",config), 'container');
        renderItemsInModal();
        $("#"+config.modal_id).on("click","#addSelectedButton", addSelected);
        $("#"+config.modal_id).on("click", ".linker-list .pagination .navigation a", function() {
          renderItemsInModal($(this).attr("rel"));
        });
        return false; // IE patch
      };


      var formatResults = function(searchData) {
        var formattedResults = [];

        var currentlySelectedIds = [];
        $.each($this.tokenInput("get"), function(obj) {currentlySelectedIds.push(obj.id);});

        $.each(searchData.search_data.results, function(index, obj) {
          // only allow selection of unselected items

          if ($.inArray(obj.uri, currentlySelectedIds) === -1) {
            formattedResults.push({
              name: obj.title,
              id: obj.id,
              json: obj
            });
          }
        });
        return formattedResults;
      };


      var addEventBindings = function() {
        $(".linker-browse-btn", $linkerWrapper).on("click", showLinkerBrowseModal);
        $(".linker-create-btn", $linkerWrapper).on("click", showLinkerCreateModal);
        $this.on("tokeninput.enter", showLinkerCreateModal);
      };


      var clearTokens = function() {
        // as tokenInput plugin won't clear a token
        // if it has an input.. remove all inputs first!
        var $tokenList = $(".token-input-list", $this.parent());
        for (var i=0; i<$this.tokenInput("get").length; i++) {
          var id_to_remove = $this.tokenInput("get")[i].id.replace(/\//g,"_");
          $("#"+id_to_remove + " :input", $tokenList).remove();
        }
        $this.tokenInput("clear");
      };


      var enableSorting = function() {
        if ($(".token-input-list", $linkerWrapper).data("sortable")) {
          $(".token-input-list", $linkerWrapper).sortable("destroy");
        }
        $(".token-input-list", $linkerWrapper).sortable({
          items: 'li.token-input-token'
        });
        $(".token-input-list", $linkerWrapper).off("sortupdate").on("sortupdate", function() {
          $this.parents("form:first").triggerHandler("formchanged.aspace");
        });
      };

      var tokensForPrepopulation = function() {
        if ($this.data("multiplicity") === "one") {
          if ($.isEmptyObject($this.data("selected"))) {
            return [];
          }
          return [{
              id: $this.data("selected").uri,
              name: $this.data("selected").title,
              json: $this.data("selected")
          }];
        } else {
          if (!$this.data("selected") || $this.data("selected").length === 0) {
            return [];
          }

          return $this.data("selected").map(function(item) {
            return {
              id: item.uri,
              name: item.title,
              json: item
            };
          });
        }
      };


      var init = function() {
        var tokenInputConfig = $.extend({}, AS.linker_locales, {
          animateDropdown: false,
          preventDuplicates: true,
          allowFreeTagging: false,
          tokenLimit: (config.multiplicity==="one"? 1 :null),
          caching: false,
          onCachedResult: formatResults,
          onResult: formatResults,
          zindex: 1100,
          tokenFormatter: function(item) {
            var tokenEl = $(AS.renderTemplate("linker_selectedtoken_template", {item: item, config: config}));
            $("input[name*=resolved]", tokenEl).val(JSON.stringify(item.json));
            return tokenEl;
          },
          resultsFormatter: function(item) {
            var string = item.name;
            var $resultSpan = $("<span class='"+ item.json.jsonmodel_type + "'>");
            $resultSpan.text(string);
            $resultSpan.prepend("<span class='icon-token'></span>");
            var $resultLi = $("<li>");
            $resultLi.append($resultSpan);
            return $resultLi[0].outerHTML;
          },
          prePopulate: tokensForPrepopulation(),
          onDelete: function() {
            $this.triggerHandler("change");
          },
          onAdd:  function(item) {
            if (config.sortable && config.multiplicity == "many") {
              enableSorting();
            }
            $this.triggerHandler("change");
            $(document).triggerHandler("init.popovers");
          },
          formatQueryParam: function(q, ajax_params) {
            if ($this.tokenInput("get").length || config.exclude_ids.length) {
              var currentlySelectedIds = $.merge([], config.exclude_ids);
              $.each($this.tokenInput("get"), function(obj) {currentlySelectedIds.push(obj.id);});

              ajax_params.data["exclude[]"] = currentlySelectedIds;
            }
            if (config.types && config.types.length) {
              ajax_params.data["type"] = config.types;
            }

            return (q+"*").toLowerCase();
          }
        });


        $this.tokenInput(config.url, tokenInputConfig);

        $("> :input[type=text]", $(".token-input-input-token", $this.parent())).attr("placeholder", AS.linker_locales.hintText);

        $this.parent().addClass("multiplicity-"+config.multiplicity);

        if (config.sortable && config.multiplicity == "many") {
          enableSorting();
          $linkerWrapper.addClass("sortable");
        }

        $(document).triggerHandler("init.popovers");

        addEventBindings();
      };

      init();
    });
  };
});

$(document).ready(function() {
  $(document).bind("loadedrecordform.aspace", function(event, $container) {
    $(".linker:not(.initialised)", $container).linker();
  });

  $(".linker:not(.initialised)").linker();

  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    $(".linker:not(.initialised)", subform).linker();
  });
});
