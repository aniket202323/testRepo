
CREATE PROCEDURE dbo.spPO_getCustomProperties
@PP_Id	 			int				= null




AS
    /*
    checking of PP_Id is not required here, because it is checked with PO permission, beforehand by core service
    IF (NOT EXISTS(SELECT 1 FROM Production_Plan WHERE PP_Id = @PP_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

     */
select Process_Order_Id, Property_definition_id, Value from process_order_custom_property_value where Process_Order_Id = @PP_Id;
