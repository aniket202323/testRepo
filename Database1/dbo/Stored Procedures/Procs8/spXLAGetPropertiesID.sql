Create Procedure dbo.spXLAGetPropertiesID
@Desc varchar(50)
AS 
  Select * From Product_Properties where prop_desc = @Desc
