/*
Get Variable Specs values along with prod changes for a given variable and time frame
*/
CREATE PROCEDURE [dbo].[spBF_GetVariableSpecificationLimit_TimeFrame]
@varId                             INT = NULL,
@startDate                         Datetime = NULL,
@endDate                           Datetime = NULL
AS 
BEGIN
       SET NOCOUNT ON
       DECLARE @ProductionStarts TABLE (ProductId INT)
       DECLARE @VariableSpec Table
       (
              Id Int Identity(1,1),
              VarId INT,
              ProductId INT,
              LReject nvarchar(25), 
              LWarning nvarchar(25),
              UReject nvarchar(25),
              UWarning nvarchar(25),
              StartDate DATETIME,
 	  	  	   ProdDesc nvarchar(50)
       )
       DECLARE @CountProductionStarts Int,
            @PUId Int,
            @ConvertedST DateTime,
            @ConvertedET DateTime,
            @DbTZ nVarChar(200)
 	 
 	 SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startDate,'UTC')
    SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endDate,'UTC')
    SELECT @DbTZ = value from site_parameters where parm_id=192
 	   SELECT @PUId = PU_Id From Variables Where Var_Id = @varId
       -- Identify product changes
 	   INSERT INTO @ProductionStarts(ProductId) Select Distinct ProdId From dbo.fnBF_GetPSFromEvents(@PUId,@ConvertedST, @ConvertedET,0)
  IF EXISTS (  SELECT 1   FROM @ProductionStarts )
       BEGIN
            INSERT INTO @VariableSpec(VarId ,ProductId ,LReject , LWarning ,UReject ,UWarning, StartDate,ProdDesc)
 	  	  	 SELECT VarId = VS.Var_Id,
                     ProductId = VS.Prod_Id,    
                     LReject = VS.L_Reject, 
                     LWarning = VS.L_Warning,
                     UReject = VS.U_Reject,
                     UWarning = VS.U_User,
                     StartDate = vs.Effective_Date,
 	  	  	  	  	  ProdDesc = (select Prod_desc from Products_Base WITH(NOLOCK) where Prod_Id = VS.Prod_Id)
              FROM Var_Specs VS WITH(NOLOCK)
 	  	  	   JOIN @ProductionStarts ps ON ps.ProductId = vs.Prod_Id 
              WHERE VS.Var_Id = @varId
              AND (VS.Effective_Date <= @endDate 
              AND (VS.Expiration_date IS NULL OR VS.Expiration_date > @ConvertedST))
              ORDER BY VS.Effective_Date
              UPDATE @VariableSpec SET StartDate = @ConvertedST WHERE StartDate < @ConvertedST
                     IF EXISTS (SELECT 1 FROM @VariableSpec )
                     BEGIN
                           SELECT Id,VarId,ProductId ,LReject,LWarning ,UReject,UWarning,dbo.fnServer_CmnConvertTime(StartDate, @DbTZ,'UTC') StartDate,  ProdDesc
 	  	  	  	  	  	     FROM @VariableSpec
 	  	  	  	  	  	  	 Order by ProductId, StartDate                                                         
                     END
                     ELSE
                     BEGIN
 	                      -- Returning -999 when the entered Input ID is not present in DB
                        SELECT -999
                     END
       END
  ELSE
  BEGIN
       SELECT -999
  END 
END
