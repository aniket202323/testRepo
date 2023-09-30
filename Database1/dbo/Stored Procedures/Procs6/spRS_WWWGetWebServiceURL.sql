CREATE PROCEDURE [dbo].[spRS_WWWGetWebServiceURL]
AS
Select Parm_Id, Value From Site_Parameters Where Parm_Id in (27,30,310)
-- Results Should Be Similiar To The Following:
/*
Parm_Id     Value                                
----------- -------------------------------------
27          usgb007
30          Apps/
310         WebServices/Authentication.asmx?WSDL
*/
