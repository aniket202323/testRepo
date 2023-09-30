CREATE PROCEDURE dbo.spEM_GetEmailMessageUDP
 	 @MessageId 	  	 Int
AS
Select [Tag] =  Char(1) + '1' + Char(1) +  Convert(nVarChar(10),tfv.Table_Field_Id) + Char(2) + Char(1) + '2' + Char(1) + + Convert(nVarChar(10),tf.ED_Field_Type_Id) + Char(2) + Char(1) + '3' + Char(1) +  + eft.Field_Type_Desc + Char(2),[User Defined Field] = tf.Table_Field_Desc,tfv.Value
 	 From Table_Fields_Values tfv
 	 Join Table_Fields tf On tfv.Table_Field_Id = tf.Table_Field_Id
 	 Join Ed_Fieldtypes eft On eft.ED_Field_Type_Id = tf.ED_Field_Type_Id
Where tfv.TableId = 38 and KeyId = @MessageId
Order by tf.Table_Field_Desc
