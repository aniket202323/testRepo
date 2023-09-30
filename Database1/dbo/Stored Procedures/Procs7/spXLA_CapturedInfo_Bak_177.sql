--spXLA_CapturedInfo (mt/1-3-2002) is modified from spXLACapturedInfo_New. ECR #25128: mt/3-12-2003: Changed
--  to handle duplicate PU_Desc which could exist in database; MSI doesn't enforce uniqueness of PU_Desc
--
CREATE PROCEDURE dbo.[spXLA_CapturedInfo_Bak_177] 
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @Pu_Id  	  	 Integer
 	 , @Pu_Desc 	  	 Varchar(50) = NULL
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @NeedProductCode 	 TinyInt 	  	 --1=Need it, include in ResultSet, 0=don't need, exclude from ResultSet
 	 , @TimeSort  	  	 SmallInt 
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @ProductionUnitCount 	 Integer
--Verify Production Unit Information first
SELECT @ProductionUnitCount = 0
If @Pu_Desc Is NULL AND @PU_Id Is NULL 
  BEGIN
    SELECT [ReturnStatus] = -105 	 --Production Unit NOT SPECIFIED
    RETURN
  END
Else If @PU_Desc Is NULL --we have PU_Id
  BEGIN
    SELECT @PU_Desc = PU_Desc FROM Prod_Units WHERE PU_Id = @PU_Id
    SELECT @ProductionUnitCount = @@ROWCOUNT
    If @ProductionUnitCount = 0
      BEGIN
        SELECT [ReturnStatus] = -100 	 --Production unit specified NOT FOUND
        RETURN
      END
    --EndIf
  END
Else --we have @PU_Desc
  BEGIN
    SELECT @Pu_Id = Pu_Id FROM Prod_Units WHERE Pu_Desc = @Pu_Desc
    SELECT @ProductionUnitCount = @@ROWCOUNT
    If @ProductionUnitCount <> 1 -- Error occur
      BEGIN
        If @ProductionUnitCount = 0
          SELECT [ReturnStatus] = -100 	 --Production Unit specified NOT FOUND        
        Else --got more than one Pu_Desc
          SELECT [ReturnStatus] = -103 	 --DUPLICATE Production Unit FOUND         
        --EndIf:
        RETURN
      END
    --EndIf: Error
  END
--EndIf: handle error in PU
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
--Categorize query based on input parameters
DECLARE @QueryType  	  	  	 TinyInt
DECLARE @SingleProduct  	  	  	 TinyInt
DECLARE @SingleGroup  	  	  	 TinyInt
DECLARE @SingleCharacteristic  	  	 TinyInt
DECLARE @GroupAndProperty  	  	 TinyInt
DECLARE @NoProductInfo 	   	  	 TinyInt
DECLARE @SingleProductNoEndTime 	  	 TinyInt
DECLARE @SingleGroupNoEndTime 	  	 TinyInt
DECLARE @SingleCharacteristicNoEndTime 	 TinyInt
DECLARE @GroupAndPropertyNoEndTime  	 TinyInt
DECLARE @NoProductInfoNoEndTime 	  	 TinyInt
SELECT @SingleProduct  	  	  	 = 1
SELECT @SingleGroup  	  	  	 = 2
SELECT @SingleCharacteristic  	  	 = 3
SELECT @GroupAndProperty  	  	 = 4
SELECT @NoProductInfo 	   	  	 = 5
SELECT @SingleProductNoEndTime 	  	 = 6
SELECT @SingleGroupNoEndTime 	  	 = 7
SELECT @SingleCharacteristicNoEndTime 	 = 8
SELECT @GroupAndPropertyNoEndTime  	 = 9
SELECT @NoProductInfoNoEndTime 	  	 = 10
If @End_Time Is NOT NULL
  BEGIN
    If @Prod_Id Is Not Null  	  	  	  	  	 SELECT @QueryType = @SingleProduct
    Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL  	  	 SELECT @QueryType = @SingleGroup
    Else If @Group_Id Is Null AND @Prop_Id Is NOT NULL  	  	 SELECT @QueryType = @SingleCharacteristic
    Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty
    Else  	  	  	  	  	  	  	 SELECT @QueryType = @NoProductInfo
  END
Else
  BEGIN
    If @Prod_Id Is Not Null  	  	  	  	  	 SELECT @QueryType = @SingleProductNoEndTime
    Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL  	  	 SELECT @QueryType = @SingleGroupNoEndTime
    Else If @Group_Id Is Null AND @Prop_Id Is NOT NULL  	  	 SELECT @QueryType = @SingleCharacteristicNoEndTime
    Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndPropertyNoEndTime
    Else  	  	  	  	  	  	  	 SELECT @QueryType = @NoProductInfoNoEndTime
  END
--EndIf
If @NeedProductCode = 1 GOTO DO_PRODUCT_CODE_SQL
-- **************************************************************************************************************
-- **************************************************************************************************************
-- **************************************************************************************************************
-- **************************************************************************************************************
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Retrieve recordset based on query type
If @QueryType = @NoProductInfoNoEndTime
  BEGIN 	 
    If @TimeSort = 1 	 --Ascending
      SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone)
 	  	  FROM gb_dset WHERE Pu_id = @Pu_Id AND TimeStamp = @Start_Time ORDER BY TimeStamp ASC
    Else
      SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone)
 	  	  FROM gb_dset WHERE Pu_id = @Pu_Id AND TimeStamp = @Start_Time ORDER BY TimeStamp DESC
    --EndIf
    END
Else If @QueryType = @NoProductInfo
  BEGIN
    If @TimeSort = 1 	 --Ascending
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone)  
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time 
      ORDER BY TimeStamp ASC
    Else
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone)  
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time 
      ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @SingleProductNoEndTime
    BEGIN
      If @TimeSort = 1 	 --Ascending
         SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id AND TimeStamp = @Start_Time AND Prod_Id = @Prod_Id 
      ORDER BY TimeStamp ASC
    Else
        SELECT * 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id AND TimeStamp = @Start_Time AND Prod_Id = @Prod_Id 
      ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @SingleProduct
  BEGIN
    If @TimeSort =  1 	 --Ascending        
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time AND Prod_Id = @Prod_Id
      ORDER BY TimeStamp ASC
    Else
       SELECT * 
         FROM gb_dset 
        WHERE Pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time AND Prod_Id = @Prod_Id
     ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @SingleGroupNoEndTime
  BEGIN
    If @TimeSort = 1 	 --Ascending
    SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
      FROM gb_dset 
     WHERE Pu_id = @Pu_Id 
       AND TimeStamp = @Start_Time 
       AND Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
      ORDER BY TimeStamp ASC
    Else
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp = @Start_Time 
           AND Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
      ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @SingleGroup
  BEGIN
    If @TimeSort = 1 	 --Ascending
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp BETWEEN @Start_Time AND @End_Time 
           AND Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
      ORDER BY TimeStamp ASC
    Else
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp BETWEEN @Start_Time AND @End_Time 
           AND Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
      ORDER BY TimeStamp DESC
    --EndIf
    END
Else If @QueryType = @SingleCharacteristicNoEndTime
  BEGIN
    If @TimeSort = 1 	 --Ascending
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp = @Start_Time 
           AND Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
      ORDER BY TimeStamp ASC
    Else
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp = @Start_Time 
           AND Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
      ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @SingleCharacteristic
  BEGIN
    If @TimeSort = 1 	 --Ascending
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp BETWEEN @Start_Time AND @End_Time 
           AND Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
      ORDER BY TimeStamp ASC
    Else
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone)
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp BETWEEN @Start_Time AND @End_Time 
           AND Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
      ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @GroupAndPropertyNoEndTime
  BEGIN
    If @TimeSort = 1 	 --Ascending
      SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
        FROM gb_dset 
       WHERE Pu_id = @Pu_Id 
         AND TimeStamp = @Start_Time 
         AND Prod_Id IN 
             ( SELECT c.Prod_Id 
                 FROM Pu_Characteristics c 
                 JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id 
                WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
             )
      ORDER BY TimeStamp ASC
    Else
      SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
        FROM gb_dset 
       WHERE Pu_id = @Pu_Id 
         AND TimeStamp = @Start_Time 
         AND Prod_Id IN 
             ( SELECT c.Prod_Id 
                 FROM Pu_Characteristics c 
                 JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id 
                WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
             )
      ORDER BY TimeStamp DESC
    --EndIf
  END
Else If @QueryType = @GroupAndProperty
  BEGIN
    If @TimeSort = 1 	 --Ascending
    SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
      FROM gb_dset 
     WHERE Pu_id = @Pu_Id 
       AND TimeStamp BETWEEN @Start_Time AND @End_Time 
       AND Prod_Id IN ( SELECT c.Prod_Id 
 	  	  	   FROM Pu_Characteristics c 
 	  	  	   JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id 
 	  	  	  WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id 
 	  	  	    AND g.Product_Grp_Id = @Group_Id
 	  	       )
      ORDER BY TimeStamp ASC
    Else
        SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(Timestamp,@InTimeZone) 
          FROM gb_dset 
         WHERE Pu_id = @Pu_Id 
           AND TimeStamp BETWEEN @Start_Time AND @End_Time 
           AND Prod_Id IN 
               ( SELECT c.Prod_Id 
                   FROM Pu_Characteristics c 
                   JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id 
                  WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
               )
      ORDER BY TimeStamp DESC
    --EndIf
  END
--EndIf @QueryType ...
GOTO EXIT_PROCEDURE
-- **************************************************************************************************************
-- **************************************************************************************************************
-- **************************************************************************************************************
-- **************************************************************************************************************
DO_PRODUCT_CODE_SQL:
  --Retrieve recordset based on query type
  If @QueryType = @NoProductInfoNoEndTime
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time 
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time 
        ORDER BY ds.TimeStamp DESC
      --EndIf
      END
  Else If @QueryType = @NoProductInfo
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @SingleProductNoEndTime
      BEGIN
        If @TimeSort = 1  --Ascending
           SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time AND ds.Prod_Id = @Prod_Id
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time AND ds.Prod_Id = @Prod_Id
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @SingleProduct
    BEGIN
      If @TimeSort =  1 --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time AND ds.Prod_Id = @Prod_Id
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time AND ds.Prod_Id = @Prod_Id
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @SingleGroupNoEndTime
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp = @Start_Time
             AND ds.Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp = @Start_Time
             AND ds.Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @SingleGroup
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
             AND ds.Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
             AND ds.Prod_Id IN ( SELECT g.Prod_Id FROM Product_Group_Data g WHERE g.Product_Grp_Id = @Group_Id )
        ORDER BY ds.TimeStamp DESC
      --EndIf
      END
  Else If @QueryType = @SingleCharacteristicNoEndTime
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp = @Start_Time
             AND ds.Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp = @Start_Time
             AND ds.Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @SingleCharacteristic
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
             AND ds.Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
             AND ds.Prod_Id IN ( SELECT c.Prod_Id FROM Pu_Characteristics c WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id )
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @GroupAndPropertyNoEndTime
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp = @Start_Time
             AND ds.Prod_Id IN
                 ( SELECT c.Prod_Id
                     FROM Pu_Characteristics c
                     JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id
                    WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
                 )
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp = @Start_Time
             AND ds.Prod_Id IN
                 ( SELECT c.Prod_Id
                     FROM Pu_Characteristics c
                     JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id
                    WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
                 )
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  Else If @QueryType = @GroupAndProperty
    BEGIN
      If @TimeSort = 1  --Ascending
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
             AND ds.Prod_Id IN 
                 ( SELECT c.Prod_Id
                     FROM Pu_Characteristics c
                     JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id
                     WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
                 )
        ORDER BY ds.TimeStamp ASC
      Else
          SELECT p.Prod_Code, ds.DSet_Id,ds.Comment_Id,ds.Operator,ds.Prod_Id,
ds.PU_Id,[Timestamp] = dbo.fnServer_CmnConvertFromDbTime(ds.Timestamp,@InTimeZone)
            FROM gb_dset ds
            JOIN Products p ON p.Prod_Id = ds.Prod_Id
           WHERE ds.Pu_id = @Pu_Id
             AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
             AND ds.Prod_Id IN
                 ( SELECT c.Prod_Id
                     FROM Pu_Characteristics c
                     JOIN Product_Group_Data g ON c.Prod_Id = g.Prod_Id
                    WHERE c.Prop_Id = @Prop_Id AND c.Char_Id = @Char_Id AND g.Product_Grp_Id = @Group_Id
                 )
        ORDER BY ds.TimeStamp DESC
      --EndIf
    END
  --EndIf @QueryType ...
  GoTo EXIT_PROCEDURE
-- **************************************************************************************************************
-- **************************************************************************************************************
-- **************************************************************************************************************
-- **************************************************************************************************************
EXIT_PROCEDURE:
