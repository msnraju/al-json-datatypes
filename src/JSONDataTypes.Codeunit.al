codeunit 50100 "JSON DataTypes"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        JSalesOrder: JsonObject;
        JsonText: Text;
    begin
        JSalesOrder := SalesOrderToJson(Rec);
        JSalesOrder.WriteTo(JsonText);
        Message('%1', JsonText);

        ReadSalesOrderJson(JSalesOrder, SalesHeader);
    end;

    local procedure SalesOrderToJson(SalesHeader: Record "Sales Header"): JsonObject
    var
        JSalesOrder: JsonObject;
    begin
        // Sales Order Properties
        JSalesOrder.Add('orderNo', SalesHeader."No.");
        JSalesOrder.Add('orderDate', SalesHeader."Order Date");
        JSalesOrder.Add('sellToCustomerNo', SalesHeader."Sell-to Customer No.");
        JSalesOrder.Add('amountIncludingVAT', SalesHeader."Amount Including VAT");
        JSalesOrder.Add('isApprovedForPosting', SalesHeader.IsApprovedForPosting());
        JSalesOrder.Add('lines', SalesLinesToJson(SalesHeader));
        exit(JSalesOrder);
    end;

    local procedure SalesLinesToJson(SalesHeader: Record "Sales Header"): JsonArray
    var
        SalesLine: Record "Sales Line";
        JSalesLines: JsonArray;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                AddSalesLineToJson(SalesLine, JSalesLines);
            until SalesLine.Next() = 0;

        exit(JSalesLines);
    end;

    local procedure AddSalesLineToJson(SalesLine: Record "Sales Line"; JSalesLines: JsonArray)
    var
        JSalesLine: JsonObject;
    begin
        // Sales Line Attributes
        JSalesLine.Add('type', SalesLine.Type.AsInteger());
        JSalesLine.Add('no', SalesLine."No.");
        JSalesLine.Add('quantity', SalesLine.Quantity);
        JSalesLine.Add('unitPrice', SalesLine."Unit Price");
        JSalesLine.Add('amount', SalesLine."Line Amount");

        JSalesLines.Add(JSalesLine);
    end;

    local procedure ReadSalesOrderJson(JSalesOrder: JsonObject; SalesHeader: Record "Sales Header")
    var
        JOrderNoToken: JsonToken;
        JOrderDateToken: JsonToken;
        JSellToCustomerNoToken: JsonToken;
        JLinesToken: JsonToken;
        JLinesArray: JsonArray;
    begin
        if JSalesOrder.Get('orderNo', JOrderNoToken) then
            SalesHeader."No." := CopyStr(JOrderNoToken.AsValue().AsCode(), 1, 20);

        if JSalesOrder.Get('orderDate', JOrderDateToken) then
            SalesHeader."Order Date" := JOrderDateToken.AsValue().AsDate();

        if JSalesOrder.Get('sellToCustomerNo', JSellToCustomerNoToken) then
            SalesHeader."Sell-to Customer No." := CopyStr(JSellToCustomerNoToken.AsValue().AsCode(), 1, 20);

        if JSalesOrder.Get('lines', JLinesToken) then begin
            JLinesArray := JLinesToken.AsArray(); // Array of Objects
            ReadSalesLinesJson(JLinesArray, SalesHeader);
        end;
    end;

    local procedure ReadSalesLinesJson(JSalesLines: JsonArray; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        JSalesLineToken: JsonToken;
        JSalesLine: JsonObject;

        JTypeToken: JsonToken;
        JNoToken: JsonToken;
        JQuantityToken: JsonToken;
    begin
        foreach JSalesLineToken in JSalesLines do begin
            JSalesLine := JSalesLineToken.AsObject();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";

            if JSalesLine.Get('type', JTypeToken) then
                SalesLine.Type := "Sales Line Type".FromInteger(JTypeToken.AsValue().AsInteger());

            if JSalesLine.Get('no', JNoToken) then
                SalesLine."No." := CopyStr(JNoToken.AsValue().AsCode(), 1, 20);

            if JSalesLine.Get('quantity', JQuantityToken) then
                SalesLine.Quantity := JQuantityToken.AsValue().AsDecimal();
        end;
    end;
}