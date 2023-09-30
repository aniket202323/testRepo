Create Procedure dbo.spSDK_QueryWasteMeas
 	 @LineMask  	  	  	 nvarchar(50) = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 WasteMeasurementId = WEMT_Id,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc,
 	  	  	 MeasurementName = WEMT_Name, 
 	  	  	 Conversion = Conversion
 	 FROM 	 Prod_Lines pl
 	 JOIN 	 Prod_Units pu  	  	  	 ON  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	 JOIN 	 Waste_Event_Meas wem 	 ON wem.PU_Id = pu.PU_Id
