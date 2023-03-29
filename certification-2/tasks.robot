*** Settings ***
Documentation       order robots

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             Collections
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${DOWNLOAD_PATH}                ${CURDIR}
${Robot_url}                    https://robotsparebinindustries.com/#/robot-order
${sales_rep}
${key1}
${file_elem}
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       3s


*** Tasks ***
order your robot
    Set Selenium Speed    60 seconds
    Download the CSV file
    Get orders
    Archive receipt


*** Keywords ***
Open the robot order website
    Open Available Browser    ${Robot_url}
    Click Element    xpath=/html/body/div/div/div[2]/div/div/div/div/div/button[1]

Download the CSV file
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${DOWNLOAD_PATH}    overwrite=True

Build and order your robot
    [Arguments]    ${column}

    Wait Until Element Is Visible    head
    Click Element    head

    #Click Element    ${column}[Head]
    #Wait Until Element Is Visible
    #...    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[1]/select/option[${column}[Head]]
    #Click Element    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[1]/select/option[${column}[Head]]
    Click Element    xpath=//*[@id="head"]/option[${column}[Head]]

    Click Element    xpath=//*[@id="id-body-${column}[Body]"]

    Input Text    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${column}[Legs]

    Input Text    address    ${column}[Address]

    take scrennshot of robot    ${column}
    #Wait Until Element Is Visible    //*[@id="order"]
    #Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Button    order
    ${status}=    Run Keyword And Return Status    Click Button    order
    IF    '${status}' == "False"
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Button    order
    END
    IF    '${status}' == "True"
        Store the order receipt as a PDF    ${column}
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click Button
        ...    order-another
    END

    #Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Button    order-another
    Click Element When Visible    xpath=/html/body/div/div/div[2]/div/div/div/div/div/button[1]

Store the order receipt as a PDF
    [Arguments]    ${column}

    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Screenshot
    ...    //*[@id="receipt"]
    ...    ${CURDIR}${/}output/receiptimg/robot_receipt${column}[Order number].png

    ${pdf}=    Create List
    ...    ${CURDIR}${/}output/receiptimg/robot_receipt${column}[Order number].png
    ...    ${CURDIR}${/}output/robotimg/robot_order${column}[Order number].png

    Add Files To Pdf    ${pdf}    ${CURDIR}${/}output/receipts/robot${column}[Order number].pdf

take scrennshot of robot
    [Arguments]    ${column}
    Click Button    preview

    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Screenshot
    ...    //*[@id="robot-preview-image"]
    ...    ${CURDIR}${/}output/robotimg/robot_order${column}[Order number].png

Get orders
    ${table}=    Read table from CSV    orders.csv
    Open the robot order website
    FOR    ${column}    IN    @{table}
        Log    ${table.columns}

        Run Keyword And Continue On Failure    Build and order your robot    ${column}
    END

Archive receipt
    Archive Folder With Zip    ${CURDIR}${/}output/receipts    receipts.zip
