"use strict";

$(function () {
    $("#url").keypress(function (e) {
        if (e.which === "\r".codePointAt(0)) {
            setAnchorToURL();
        }
    });

    $("#submit").click(setAnchorToURL);

    fetchResult();
});

window.onhashchange = fetchResult;

document.onselectionchange = function() {
    const selection = document.getSelection(),
          selectedText = selection.toString(),
          selectedNode = selection.anchorNode;

    if (
        selectedNode &&
        selectedNode.parentNode.nodeName.toLowerCase() === "code" &&
        selectedNode.isSameNode(selection.focusNode) &&
        selectedText !== ""
    ) {
        $("#url").val(selectedText);
    }
};

function setAnchorToURL() {
    window.location.hash = $("#url").val();
}

function fetchResult() {
    $("#result").css("display", "none");
    $("#failure").css("display", "none");

    if (!window.location.hash) {
        return;
    }

    let decodedURL = decodeURIComponent(window.location.hash.substring(1));

    $("#url").val(decodedURL);

    /* Keep `label` from overlapping the text above. */
    $("label[for='url']").removeClass().addClass("active");

    if (decodedURL === "robots.txt") {
        decodedURL = "Robots.txt"; /* Avoid the `/robots.txt` endpoint. */
    }

    $.ajax({
        type: "GET",
        url: "<%= $c->url_for ('api') %>" + encodeURIComponent(decodedURL),
        dataType: "json",
        success: displayResult,
        error: displayError
    });

    /* String Slice-n-Dice Demystified
     *
     *   window.location.hash: Get anchor string of current page. We are
     *                         (mis)?using that to hold URLs to make the page
     *                         bookmarkable.
     *
     *   .substring(1): Strip the leading `#` from the anchor obtained above,
     *                  as that is not part of the URL we want to split.
     *
     *   decodeURIComponent: `window.location.hash` returns UTF8 characters as
     *                       URL-encoded, so this round of decoding takes care
     *                       of that.
     *
     *   encodeURIComponent: `#` cannot be part of a URL, so the whole path
     *                       part of the AJAX call has to be URL-encoded to
     *                       allow safe passage for `#` through HTTP.
     */
}

function displayResult(data) {
    $("#scheme").text(data.scheme);
    $("#username").text(data.username);
    $("#password").text(data.password);
    $("#hostname").text(data.hostname);
    $("#port").text(data.port);
    $("#path").text(data.path);
    $("#query").text(data.query);
    $("#anchor").text(data.anchor);
    $("#domain").text(data.domain);
    $("#public-suffix").text(data.public_suffix);

    $("#is-rulable").text(data.is_rulable ? "Yes" : "No");
    $("#is-subdomain").text(data.is_subdomain ? "Yes" : "No");
    $("#is-public-suffix").text(data.is_public_suffix ? "Yes" : "No");

    $("#result").css("display", "inline");
}

function displayError(xhr, error) {
    $("#error-message").text(
        xhr.readyState !== 4    ? "We are unable to talk to the server."  :
        error === "parsererror" ? "We are talking to the wrong server."   :
                                  "Something is wrong. Refresh the page.");

    $("#failure").css("display", "inline");
}
