CREATE TABLE [dbo].[Web_Report_Printers] (
    [Printer_Id] INT NOT NULL,
    [WRD_Id]     INT NOT NULL,
    CONSTRAINT [PK_Web_Report_Printers] PRIMARY KEY NONCLUSTERED ([WRD_Id] ASC, [Printer_Id] ASC),
    CONSTRAINT [WRP_PRINTER] FOREIGN KEY ([Printer_Id]) REFERENCES [dbo].[Report_Printers] ([Printer_Id]),
    CONSTRAINT [WRP_WRD] FOREIGN KEY ([WRD_Id]) REFERENCES [dbo].[Web_Report_Definitions] ([WRD_Id])
);

