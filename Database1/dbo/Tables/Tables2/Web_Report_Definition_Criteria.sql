CREATE TABLE [dbo].[Web_Report_Definition_Criteria] (
    [WRDC_Id]                INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comparison_Operator_Id] TINYINT NULL,
    [Value]                  INT     NULL,
    [WAC_Id]                 INT     NOT NULL,
    [WRD_Id]                 INT     NOT NULL,
    CONSTRAINT [PK_Web_Report_Definition_Criteria] PRIMARY KEY NONCLUSTERED ([WRDC_Id] ASC),
    CONSTRAINT [WRDC_COI] FOREIGN KEY ([Comparison_Operator_Id]) REFERENCES [dbo].[Comparison_Operators] ([Comparison_Operator_Id]),
    CONSTRAINT [WRDC_WAC] FOREIGN KEY ([WAC_Id]) REFERENCES [dbo].[Web_App_Criteria] ([WAC_Id]),
    CONSTRAINT [WRDC_WRD] FOREIGN KEY ([WRD_Id]) REFERENCES [dbo].[Web_Report_Definitions] ([WRD_Id])
);

