pageextension 50100 "Sales Orders Ext" extends "Sales Orders"
{
    actions
    {
        addafter("Show Order")
        {
            // Add changes to page actions here
            action("ToJson")
            {
                ApplicationArea = All;
                Caption = 'To JSON';
                ToolTip = 'Convert To JSON';

                Image = Export;
                Promoted = true;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    SalesHeader.Get("Document Type", "Document No.");
                    SalesHeader.CalcFields("Amount Including VAT");
                    Codeunit.Run(Codeunit::"JSON DataTypes", SalesHeader);
                end;
            }
        }
    }
}