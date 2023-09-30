CREATE PROCEDURE dbo.spEM_DeleteComment
  @Object_Id   int,
  @Object_Type nVarChar(2),
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success.
  --   1 = Error: Unknown object type.
  --
  -- Declare local variables.
  --
  DECLARE @Insert_Id integer,@Comment_Id int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DeleteComment',
                 convert(nVarChar(10),@Object_Id) + ','  + @Object_Type + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
--
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Remove the reference to the comment from the object.
  --
IF @Object_Type = 'ad'  	 -- Production Line
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Prod_Lines WHERE PL_Id = @Object_Id
      UPDATE Prod_Lines SET Comment_Id = NULL WHERE PL_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'ae' 	 -- Production Unit
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Prod_Units WHERE PU_Id = @Object_Id
      UPDATE Prod_Units SET Comment_Id = NULL WHERE PU_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'af' 	 -- Production Group
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM PU_Groups WHERE PUG_Id = @Object_Id
      UPDATE PU_Groups SET Comment_Id = NULL WHERE PUG_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'ag' 	 -- Variable
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Variables WHERE Var_Id = @Object_Id
      UPDATE Variables_Base SET Comment_Id = NULL WHERE Var_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'aj' 	 -- Product
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Products WHERE Prod_Id  = @Object_Id
      UPDATE Products SET Comment_Id = NULL WHERE Prod_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'al' 	 -- Product Group
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Product_Groups WHERE Product_Grp_Id = @Object_Id
      UPDATE Product_Groups SET Comment_Id = NULL WHERE Product_Grp_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'ao' 	 -- Property
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Product_Properties WHERE Prop_Id  = @Object_Id
      UPDATE Product_Properties SET Comment_Id = NULL WHERE Prop_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'aq' 	 -- Characteristic
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Characteristics WHERE Char_Id  = @Object_Id
      UPDATE Characteristics SET Comment_Id = NULL WHERE Char_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'as' 	 -- Specification
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Specifications WHERE Spec_Id  = @Object_Id
      UPDATE Specifications SET Comment_Id = NULL WHERE Spec_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'ay' 	 -- User Group
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Security_Groups WHERE Group_Id  = @Object_Id
      UPDATE Security_Groups SET Comment_Id = NULL WHERE Group_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'bg' 	 -- Transaction
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Transactions WHERE Trans_Id  = @Object_Id
      UPDATE Transactions SET Comment_Id = NULL WHERE Trans_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'br' 	 -- Sheet
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Sheets WHERE Sheet_Id  = @Object_Id
      UPDATE Sheets SET Comment_Id = NULL WHERE Sheet_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'bt' 	 -- Characteristic Group
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Characteristic_Groups WHERE Characteristic_Grp_Id  = @Object_Id
      UPDATE Characteristic_Groups SET Comment_Id = NULL WHERE Characteristic_Grp_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'by' 	 -- Reasons
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Event_Reasons WHERE Event_Reason_Id  = @Object_Id
      UPDATE Event_Reasons SET Comment_Id = NULL WHERE Event_Reason_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'dz' 	 -- Department
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Departments WHERE Dept_Id  = @Object_Id
      UPDATE Departments SET Comment_Id = NULL WHERE Dept_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'cn' 	 -- Product_Family
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Product_Family WHERE Product_Family_Id  = @Object_Id
      UPDATE Product_Family SET Comment_Id = NULL WHERE Product_Family_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'fk' 	 -- bom family
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Bill_Of_Material_Family WHERE BOM_Family_Id  = @Object_Id
      UPDATE Bill_Of_Material_Family SET Comment_Id = NULL WHERE BOM_Family_Id = @Object_Id
    END
  ELSE IF @Object_Type = 'fm' 	 -- bom
    BEGIN
      SELECT @Comment_Id = Comment_Id FROM Bill_Of_Material WHERE BOM_Id  = @Object_Id
      UPDATE Bill_Of_Material SET Comment_Id = NULL WHERE BOM_Id = @Object_Id
    END
  ELSE 	  	  	  	 -- Unknown object type.
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  --
  -- Delete the comment. (Changed 04/22/98 - Deletes Causing to much bottle necking)
  --
      UPDATE Comments SET Comment = '',ShouldDelete = 1 WHERE Comment_Id = @Comment_ID
  -- DELETE FROM Comments WHERE Comment_Id = @Comment_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
