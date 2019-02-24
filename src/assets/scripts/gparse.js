"use strict";

window.onload = function () {
    $("#url").keypress(function (e) {
        if (e.which === "\r".codePointAt(0)) {
            setAnchorToURL();
        }
    });

    fetchResult();
};

window.onhashchange = fetchResult;

function setAnchorToURL() {
    window.location.hash = $("#url").val();
}

function fetchResult() {
    clearResult();

    if (!window.location.hash) {
        return;
    }

    const decodedURL = decodeURIComponent(window.location.hash.substring(1));

    $("#url").val(decodedURL);

    /* Keep `label` from overlapping the text above. */
    $("label[for='url']").removeClass().addClass("active");

    $.ajax({
        type: "GET",
        url: `/${ encodeURIComponent(decodedURL) }`,
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
};

function clearResult() {
    $("#result").removeClass();
    $("#result").html("");
}

function safeCDATA(data) {
    return decodeURIComponent(data).replace(/</g, "&lt;");
}

function displayResult(data) {
    const table = `
        <table class="centered responsive-table striped">
            <tr>
                <td>Scheme</td>
                <td><code>${ safeCDATA(data.scheme) }</code></td>
            </tr>
            <tr>
                <td>Username</td>
                <td><code>${ safeCDATA(data.username) }</code></td>
            </tr>
            <tr>
                <td>Password</td>
                <td><code>${ safeCDATA(data.password) }</code></td>
            </tr>
            <tr>
                <td>Hostname</td>
                <td><code>${ safeCDATA(data.hostname) }</code></td>
            </tr>
            <tr>
                <td>Port</td>
                <td><code>${ safeCDATA(data.port) }</code></td>
            </tr>
            <tr>
                <td>Path</td>
                <td><code>${ safeCDATA(data.path) }</code></td>
            </tr>
            <tr>
                <td>Query</td>
                <td><code>${ safeCDATA(data.query) }</code></td>
            </tr>
            <tr>
                <td>Anchor</td>
                <td><code>${ safeCDATA(data.anchor) }</code></td>
            </tr>
            <tr>
                <td>Domain</td>
                <td><code>${ safeCDATA(data.domain) }</code></td>
            </tr>
            <tr>
                <td>Public Suffix</td>
                <td><code>${ safeCDATA(data.public_suffix) }</code></td>
            </tr>
            <tr>
                <td>Rulable?</td>
                <td><code>${ data.is_rulable ? "Yes" : "No" }</code></td>
            </tr>
            <tr>
                <td>Sub-Domain?</td>
                <td><code>${ data.is_subdomain ? "Yes" : "No" }</code></td>
            </tr>
            <tr>
                <td>Public Suffix?</td>
                <td><code>${ data.is_public_suffix ? "Yes" : "No" }</code></td>
            </tr>
        </table>
    `;

    $("#result").removeClass().addClass("card-panel hoverable col m6 s10 " +
                                        "offset-m3 offset-s1");
    $("#result").html(table);
}

function displayError(xhr, error) {
    const message =
        xhr.readyState !== 4    ? "We are unable to talk to the server."  :
        error === "parsererror" ? "We are talking to the wrong server."   :
                                  "Something is wrong. Refresh the page." ;

    $("#result").removeClass().addClass("card-panel hoverable col m6 s10 " +
                                        "offset-m3 offset-s1 red white-text");
    $("#result").html(`<p>${ message }</p>`);
}
