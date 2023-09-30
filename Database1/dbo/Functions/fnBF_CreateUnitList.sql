CREATE FUNCTION dbo.fnBF_CreateUnitList(@PLId Int,@UnitList VarChar(7000))
 RETURNS @returnTable TABLE (PUId Int)
  AS
BEGIN
 	 IF @PLId Is Null and @UnitList Is Null
 	 BEGIN
 	  	 INSERT INTO @returnTable(PUId)
 	  	  	 SELECT PU_Id
 	  	  	  	 FROM Prod_Units
 	  	  	  	 WHERE (Master_Unit Is Null or  Master_Unit = PU_Id) AND PU_Id > 0
 	 END
 	 ELSE IF @PLId Is Not Null
 	 BEGIN
 	  	 INSERT INTO @returnTable(PUId)
 	  	  	 SELECT PU_Id
 	  	  	  	 FROM Prod_Units
 	  	  	  	 WHERE PL_Id = @PLId and (Master_Unit Is Null or  Master_Unit = PU_Id) AND PU_Id > 0
 	 END
 	 ELSE IF @UnitList Is NOT Null
 	 BEGIN
 	  	 INSERT INTO @returnTable(PUId)
 	  	  	 SELECT Distinct Id 
 	  	  	 FROM fnCMN_IdListToTable( 'Prod_Units',@UnitList,',')
 	  	 DELETE @returnTable
 	  	 FROM @returnTable a
 	  	 Join Prod_Units b on b.PU_Id = a.PUId 
 	  	 WHERE   Master_Unit Is Not Null and Master_Unit != PU_Id AND PU_Id > 0
 	 END
 	 RETURN
END
