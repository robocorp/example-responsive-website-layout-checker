*** Settings ***
Documentation     Responsive website layout checker.
...               Reports website layout in different viewport sizes.
Library           Collections
Library           RPA.Browser.Playwright
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Dialogs
Library           RPA.FileSystem
Library           RPA.PDF
Library           String

*** Variables ***
${REPORT_PATH}=    ${OUTPUT_DIR}${/}report.html

*** Tasks ***
Report website layout in different viewport sizes
    ${url}=    Get website URL
    ${viewports}=    Get viewports by unique width
    ${viewports}=    Capture layouts    ${url}    ${viewports}
    Create layout report    ${url}    ${viewports}

*** Keywords ***
Get website URL
    Add text input    url    label=Website URL
    ${result}=    Run dialog    title=Responsive website layout checker
    Log To Console    ${\n}${result.url}
    [Return]    ${result.url}

Get viewports by unique width
    New Page    https://yesviz.com/viewport/
    ${viewports}=    Create List
    ${viewport_widths}=    Create List
    ${viewport_rows}=    Get Elements    css=#viewport-table tbody tr
    FOR    ${row}    IN    @{viewport_rows}
        ${device_name}=
        ...    RPA.Browser.Playwright.Get Text
        ...    ${row} >> td:nth-child(2)
        ${formatted_device_name}=    Format device name    ${device_name}
        ${viewport_size}=
        ...    RPA.Browser.Playwright.Get Text
        ...    ${row} >> td:nth-child(3)
        ${viewport_width}=    Fetch From Left    ${viewport_size}    ${SPACE}
        ${viewport_height}=    Fetch From Right    ${viewport_size}    ${SPACE}
        IF    "${viewport_width}" not in @{viewport_widths}
            Append To List    ${viewport_widths}    ${viewport_width}
            ${device_viewport}=
            ...    Create Dictionary
            ...    device_name=${device_name}
            ...    formatted_device_name=${formatted_device_name}
            ...    width=${viewport_width}
            ...    height=${viewport_height}
            Append To List    ${viewports}    ${device_viewport}
        END
    END
    [Return]    ${viewports}

Format device name
    [Arguments]    ${device_name}
    ${formatted_device_name}=
    ...    Remove String
    ...    ${device_name}
    ...    -
    ...    .
    ...    "
    ...    (
    ...    )
    ...    ${SPACE}
    [Return]    ${formatted_device_name}

Capture layouts
    [Arguments]    ${url}    ${viewports}
    FOR    ${viewport}    IN    @{viewports}
        New Context
        ...    viewport={'width': ${viewport}[width], 'height': ${viewport}[height]}
        New Page    ${url}
        ${image_name}=
        ...    Set Variable
        ...    ${viewport}[formatted_device_name]-${viewport}[width]x${viewport}[height]
        ${file_type}=    Set Variable    png
        ${image_path}=
        ...    Set Variable
        ...    ${OUTPUT_DIR}${/}screenshots${/}${image_name}
        Take Screenshot    ${image_path}    fileType=${file_type}
        Set To Dictionary    ${viewport}    image=${image_path}.${file_type}
        Log To Console
        ...    ${viewport}[device_name]: ${viewport}[width] x ${viewport}[height]
    END
    [Return]    ${viewports}

Create layout report
    [Arguments]    ${url}    ${viewports}
    ${entries}=    Set Variable    ${EMPTY}
    FOR    ${viewport}    IN    @{viewports}
        ${entry}=    Generate report entry    ${viewport}
        ${entries}=    Catenate    ${entries}    ${entry}
    END
    ${template}=    Read File    ${CURDIR}${/}report-template.html
    ${report}=    Replace Variables    ${template}
    Create File
    ...    path=${REPORT_PATH}
    ...    content=${report}
    ...    overwrite=True
    Open Available Browser    file://${REPORT_PATH}
    Maximize Browser Window

Generate report entry
    [Arguments]    ${viewport}
    ${html}=
    ...    Catenate
    ...    SEPARATOR=${\n}
    ...    <div class="device">
    ...    <h2>${viewport}[device_name]: ${viewport}[width] x ${viewport}[height]</h2>
    ...    <img src="${viewport}[image]" />
    ...    </div>
    [Return]    ${html}
