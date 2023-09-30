CREATE TABLE [dbo].[Engineering_Unit_Conversion] (
    [Eng_Unit_Conv_Id]  INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Conversion_Desc]   VARCHAR (50) NOT NULL,
    [Custom_Conversion] TEXT         NULL,
    [From_Eng_Unit_Id]  INT          NULL,
    [Intercept]         FLOAT (53)   NULL,
    [Slope]             FLOAT (53)   NULL,
    [To_Eng_Unit_Id]    INT          NULL,
    CONSTRAINT [EngineeringUnitConv_PK_ConvId] PRIMARY KEY NONCLUSTERED ([Eng_Unit_Conv_Id] ASC),
    CONSTRAINT [EngineeringUnitConversion_CC_EmptyDesc] CHECK (len([Conversion_Desc])>(0)),
    CONSTRAINT [EngineeringUnitConversion_CC_SlopeIntercept] CHECK ([Slope] IS NULL AND [Intercept] IS NULL OR [Slope] IS NOT NULL AND [Intercept] IS NOT NULL),
    CONSTRAINT [EngineeringUnitConv_FK_FromId] FOREIGN KEY ([From_Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [EngineeringUnitConv_FK_ToId] FOREIGN KEY ([To_Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [EngineeringUnitConv_UC_ConversionDesc] UNIQUE NONCLUSTERED ([Conversion_Desc] ASC)
);


GO
CREATE NONCLUSTERED INDEX [EUConversion_IDX_FromToEngUnitId]
    ON [dbo].[Engineering_Unit_Conversion]([From_Eng_Unit_Id] ASC, [To_Eng_Unit_Id] ASC);

