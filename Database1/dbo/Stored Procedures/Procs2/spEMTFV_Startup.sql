CREATE PROCEDURE dbo.spEMTFV_Startup 
  AS
 	 DECLARE @DisplayColumns Table(ED_Field_Type_Id Int,ValueCols Int)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (1,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (2,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (9,2)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (10,3)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (11,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (12,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (22,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (23,2)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (24,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (27,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (30,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (34,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (35,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (36,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (37,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (39,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (40,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (47,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (51,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (59,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (61,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (63,1)
 	 INSERT INTO @DisplayColumns(ED_Field_Type_Id,ValueCols) Values (69,1)
 	 SELECT t.TableId,t.TableName
 	 FROM Tables t
 	 WHERE Allow_User_Defined_Property = 1
 	 ORDER BY TableName
 	 SELECT tf.TableId,[Table_Field_Desc] =  '(' + Convert(nVarChar(10),tf.TableId) + ')' + Char(1) + tf.Table_Field_Desc ,tf.Table_Field_Id, 	  	  	  	 
 	  	  	 [TAG] = Char(1) + '1' + Char(1) + convert(nVarChar(25),tf.ED_Field_Type_Id) + Char(2) + dbo.fnEM_TableFieldTagCmn(tf.Table_Field_Id,tf.TableId) 
 	 FROM Table_Fields tf 
 	 Join ED_FieldTypes ef ON ef.ED_Field_Type_Id = tf.ED_Field_Type_Id and ef.User_Defined_Property = 1
 	 ORDER BY TableId,Table_Field_Desc
 	 SELECT tf.ED_Field_Type_Id,tf.Field_Type_Desc,ValueCols = isnull(b.ValueCols,3)
 	 FROM ed_FieldTypes tf 
 	 Left Join @DisplayColumns b On b.ED_Field_Type_Id = tf.ED_Field_Type_Id
 	 WHERE User_Defined_Property = 1 and tf.ED_Field_Type_Id != 3
 	 ORDER BY Field_Type_Desc
