
CREATE PROCEDURE dbo.spActivities_GetRunningGrade @PU_Id            INT,
                                                  @TimeStamp        DATETIME      = NULL,
                                                  @LookAtAppProdId  INT,
                                                  @Prod_Id          INT OUTPUT,
                                                  @Prod_Code        NVARCHAR(100) OUTPUT,
                                                  @Start_Id         INT OUTPUT,
                                                  @Start_Time       DATETIME      = NULL OUTPUT,
                                                  @IsAppliedProduct BIT           = 0 OUTPUT


AS
BEGIN

    DECLARE @Master_Unit INT, @AppProdId INT

    SELECT @Master_Unit = Master_Unit FROM Prod_Units_Base WHERE PU_Id = @PU_Id

    IF @TimeStamp IS NULL
        BEGIN
            SET @TimeStamp = dbo.fnserver_CmnConvertToDbTime(GETUTCDATE(), 'UTC');
        END

    IF @Master_Unit IS NULL
        BEGIN
            SELECT @Master_Unit = @PU_Id
        END

    SELECT @AppProdId = NULL
    IF @LookAtAppProdId = 1
        BEGIN
            SELECT @AppProdId = Applied_Product FROM Events WHERE PU_Id = @Master_Unit
                                                                  AND TimeStamp = @TimeStamp
        END

    SELECT @Start_Id = 0
    SELECT @Start_Time = NULL

    IF @AppProdId IS NOT NULL
        BEGIN
            SELECT @Prod_Id = @AppProdId,
                   @IsAppliedProduct = 1
        END
        ELSE
        BEGIN
            SELECT @Prod_Id = ps.Prod_Id,
                   @Prod_Code = p.Prod_Code,
                   @Start_Id = ps.Start_Id,
                   @Start_Time = ps.Start_Time,
                   @IsAppliedProduct = 0
                   FROM Production_Starts AS ps
                        JOIN Products AS p ON p.Prod_Id = ps.Prod_Id
                   WHERE ps.PU_Id = @Master_Unit
                         AND ps.Start_Time <= @TimeStamp
                         AND (ps.End_Time > @TimeStamp
                              OR ps.End_Time IS NULL)
        END
END
