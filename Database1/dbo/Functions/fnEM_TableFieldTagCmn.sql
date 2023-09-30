CREATE FUNCTION dbo.fnEM_TableFieldTagCmn(@TableFieldId Int,@TableId  int) 
 	 Returns 	  nvarchar(50) 
BEGIN
 	 DECLARE @ReturnVal nVarChar(3500)
 	 SELECT  @ReturnVal = Char(1) + '10' + Char(1) + IsNull(Convert(nVarChar(10),edf.SP_Lookup),'') + Char(2)
 	  	  	  	 + Char(1) + '11' + Char(1) + IsNull(Convert(nVarChar(10),edf.Store_Id),'') + Char(2)
 	  	  	  	 + Char(1) + '12' + Char(1) + Convert(nVarChar(10),@TableId) + Char(2)
 	  	  	  	 + Char(1) + '13' + Char(1) + Convert(nVarChar(10),tf.Table_Field_Id) + Char(2)
 	  	  	 FROM  Table_Fields tf
 	  	  	 JOIN ED_FieldTypes edf ON edf.ED_Field_Type_Id = tf.ED_Field_Type_Id
 	  	  	 WHERE tf.Table_Field_Id = @TableFieldId
 	 RETURN (@ReturnVal)
END
