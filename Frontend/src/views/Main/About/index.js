import React, { PureComponent } from "react";
// import { Accordion, Item } from "devextreme-react/ui/accordion";
import styles from "./styles.module.scss";

export default class About extends PureComponent {
  render() {
    return (
      <div className={styles.aboutContainer}>
        {/* <Accordion collapsible={true} multiple={true}>
          <Item title="v4.0.4">
            <h4>Release Notes</h4>
            <ul>
              <li>
                <b>Tasks Planning Report: </b>
                Fixed: Show correct Test Time in Projected scheduled date for
                Daily and Multiday Tasks
              </li>
            </ul>
          </Item>
          <Item title="v4.0.3">
            <h4>Release Notes</h4>
            <ul>
              <li>
                <b>eCIL Scheduler Change: </b>
                Option to Auto-postpone non-fixed frequency tasks during out of
                scope line statuses.
              </li>
              <li>
                <b>Defect: </b>
                All task completion not working when grouped -- fixed.
              </li>
            </ul>
            <h4>Technology Upgrades:</h4>
            <ul>
              <li>Compatible with all modern browsers</li>
              <li>Minor functionality changes to drive touch reduction</li>
              <li>Modernized look & feel</li>
              <li>Performance Improvement</li>
            </ul>
          </Item>
          <Item title="v3.2.0 Released on 01-Mar-2018">
            <h4>Release Notes</h4>
            <ul>
              <li>Add HSE Flag to tasks</li>
              <li>Allow tasks to be scheduled by minutes</li>
              <li>Add Defect Fixed checkbox to defects screen</li>
              <li>Crews can be assigned to Routes or Team Tasks</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                <b>
                  FO-03309: Change eCIL to encrypt the password information in
                  the webconfig file.
                </b>
              </li>
              <li>
                <b>FO-04102: Update eCIL to redirect to HTTPS</b>
              </li>
            </ul>
          </Item>
          <Item title="v3.1.0 Released on 01-Aug-2015">
            <h4>Release Notes</h4>
            <ul>
              <li>
                <b>
                  Modified eCIL scheduler to support STLS as well as NPT
                  configuration. All Lines should either have STLS or NPT{" "}
                </b>
              </li>
              <li>Allow windows based and proficy based authentication</li>
              <li>
                Line Status UDP either attached to Phrases or Event Reasons
                table based on STLS or NPT
              </li>
              <li>
                <b>
                  Not able to rename task description via tasks management or
                  version management.It should be done through MDAT{" "}
                </b>
              </li>
              <li>eCIL Single Sign On support domain name as well as FQDN</li>
              <li>
                Tasks Planning Report support STLS as well as NPT configuration
              </li>
              <li>
                Applied hotfixes from eCIL 2.5.0 and eCIL 3.0.0 to eCIL 3.1.0
                version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New SQL installation script is required.</li>
              <li>New prompts are required to run this version.</li>
              <li>
                Defect Handling can be done using SAP or eDefect. This defect
                handling mode can be configured in the eCIL application
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                <b>FO-01310- </b>Version mgmt can't create new module for unique
                FL2-FL3 combination in PeCIL.
              </li>
              <li>
                <b>FO-01530- </b>Editing Single/Multiple task” functionality
                wrongly assigning the FL4 as eCIL.
              </li>
              <li>
                <b>FO-02017- </b>PeCIL-Task Mgt Box remains checked after
                saving.
              </li>
              <li>
                <b>
                  FO-02448 PeCIL Task Name Field Should Be Allowed To Be Edited
                  for PPA version 5.0 and PPA 6.x non-aspected site only
                </b>
              </li>
              <li>
                <b>FO-02448- </b>P PeCIL Task Name Field Should Be Allowed To Be
                Edited for PPA version 5.0 and PPA 6.x non-aspected site only
              </li>
              <li>
                <b>FO-03005- </b>Update eCIL login feature to authenticate the
                windows credentials.
              </li>
              <li>
                <b>FO-02982- </b>Fix the task duplicate feature to save VMID and
                TaskID.
              </li>
            </ul>
          </Item>
          <Item title="v3.0.0 Released on 16-Jan-2015">
            <h4>Release Notes</h4>
            <ul>
              <li>Proficy Plant Applications 6.1 or above is must required.</li>
              <li>
                <b>
                  Crew Schedule is fetched from Non Productive Time (NPT)
                  display
                </b>
              </li>
              <li>
                <b>Valid Line Status should be configured in Reason Tree </b>
              </li>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New SQL installation script is required.</li>
              <li>New prompts are required to run this version.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                Role based security has been implemented for authentication.
              </li>
              <li>
                <b>FO-01992</b> - Auto login menu has been added
              </li>
              <ul>
                <li>
                  Existing <b>Log In</b> menu has been removed
                </li>
              </ul>
              <li>
                <b>FO-01997</b> - Gray out task name while edit/duplicate task
              </li>
              <ul>
                <li>
                  Task name editing is disabled for Version Management as well.
                </li>
              </ul>
              <li>
                <b>FO-01996</b> -&nbsp;
                <span>
                  Allow single sign on for defect logging in SAP, changes are
                  done with respect to role based security
                </span>
              </li>
              <li>
                <b>FO-02096</b> -&nbsp;
                <span>
                  Upgrade cybersafe version 4.2.4 to 4.4.0 on windows 2008
                  servers so that single sign on works to make connection with
                  SAP
                </span>
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                <b>FO-02009</b>- Error pops up when multiple sessions of eCIL
                client open in same IE instance and client session gets timeout.
              </li>
              <li>
                <b>FO-01998- </b>Fixed the issue with Compliance Report
              </li>
              <li>
                <b>FO-02027- </b>Fixed issue related to Full Domain Name while
                auto login
              </li>
            </ul>
          </Item>
          <Item title="v2.5.0 Released on 16-May-2011">
            <h4>Release Notes</h4>
            <ul>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New SQL installation script is required.</li>
              <li>New prompts are required to run this version.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                There is a design change in Task Planning Report to add below
                additional columns in Field Chooser popup.
                <ul>
                  <li>Doc</li>
                  <li>Info</li>
                  <li>Task Freq</li>
                  <li>Task Type</li>
                  <li>Late Date</li>
                  <li>Lubricant</li>
                </ul>
              </li>
              <li>
                Wrap Mode Settings will be saved in the database for Public and
                Private views for below screens.
                <ul>
                  <li>Data Entry</li>
                  <li>Task Planning Report</li>
                </ul>
              </li>
              <li>
                New Quick print button is added in the top navigation panel on
                Data Entry screen. Clicking this button will export the current
                data in the grid with following columns in Landscape mode.
                <ul>
                  <li>FL2</li>
                  <li>FL3</li>
                  <li>Module</li>
                  <li>Task Id</li>
                  <li>Long Task Name</li>
                  <li>Items</li>
                  <li>Duration</li>
                  <li>Task Type</li>
                  <li>Q-Factor Type</li>
                  <li>Criteria</li>
                  <li>PPE</li>
                  <li>Hazards</li>
                  <li>Lubricant</li>
                  <li>Tools</li>
                  <li>Value</li>
                </ul>
              </li>
              <li>
                Added the ability to have Single Sign-On functionality for PeCIL
                system. If delegation is enabled for the server, SAP
                connectivity will be established using Single Sign On and user
                is not required to enter his credentials to create a Defect in
                SAP, provided he has a valid access on SAP server.
              </li>
              <li>
                Below PDF reports will be printed by defualt in Landscape
                orientation.
                <ul>
                  <li>Data Entry screen export</li>
                  <li>Task Planning Report</li>
                  <li>Task Management Report</li>
                  <li>Task Configuration Report</li>
                  <li>Version Management Report</li>
                </ul>
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                % Done column is not showing red color when PctDone = 0% in
                Compliance Report.
              </li>
              <li>
                Wrap mode prompt for Task Configuration Report is shown
                incorrectly.
              </li>
              <li>
                Alert message is pop-up as “Invalid Format for Defect
                Details”,when user click on missed cell in Trend Report.
              </li>
              <li>Inactive tasks appear in Task planning report.</li>
              <li>eCIL Scheduler create an instance for inactive tasks.</li>
              <li>
                Task Planning Report is throwing binary string truncated error
                message.
              </li>
              <li>
                Version Management screen will now be available only to Admin
                users.
              </li>
            </ul>
          </Item>
          <Item title="v2.4.0 Fixes Released on 06-Sep-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>SQL Stored Procedures must be updated</li>
              <li>New prompts are required to run this version.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                New validation of Plant Model configuration in Version
                Management
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>%Done greater than 100% on Compliance Report</li>
              <li>Assignment of tasks on wrong Master Unit</li>
              <li>
                Compliance Report printing does not correctly populate %Done
                when exporting to Excel (Ticket: 30536967).
              </li>
              <li>
                Compliance Report printing does not populate %Done and Stops of
                higher levels
              </li>
              <li>Obsoleted Tasks appears in Route-Tasks report</li>
              <li>Opened Defects calculation is wrong on Compliance Report</li>
              <li>
                While duplicating task from one line to another the group field
                is blank (Ticket: 30626278).
              </li>
              <li>Extract file in VM treated as invalid</li>
              <li>
                Task group is not updated even if Success in Tasks Mgmt screen
                (Ticket: 30582554).
              </li>
              <li>
                Wrong Master Unit Assignment and Group absence in Version
                Management
              </li>
            </ul>
          </Item>
          <Item title="v2.4.0 Released on 08-Jul-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New SQL installation script is required.</li>
              <li>New prompts are required to run this version.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                It is now possible to copy a task from the Tasks Management
                screen.
              </li>
              <li>
                Compliance Report can now be exported to PDF and Excel and can
                also be printed directly.
              </li>
              <li>
                New report is available to see the configuration of any task(s)
                from the Plant Model selection. This is a read-only replication
                of Tasks Management which is reserved to administrators.
              </li>
              <li>
                Tasks can now be exported in Raw Extract Format. This format can
                then be read by a CDW or Version Management screen directly.
              </li>
              <li>
                Users can now clear all filters from a link on the filter row.
              </li>
              <li>
                Multiple Assignments report now excludes tasks assigned to a
                route which is associated to one team only.
              </li>
              <li>Task Type has now a new possible value : Route.</li>
              <li>Each Master Unit of a line can now have a different FL2.</li>
              <li>
                The Plant Model in different screens now presents only sections
                (Master Unit, Slave Unit, Group) that contains eCIL variables.
              </li>
              <li>Using DevExpress v10.1.5</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Tasks that were obsoleted with v2.3.0 were not hidden from
                reports and lists.
              </li>
              <li>
                Renaming a task was failing without giving any error when trying
                to rename a task that was already existing on the same line. The
                restriction is now only limited to the Slave Unit, and an error
                message will be displayed if failing.
              </li>
              <li>
                String or Binary data would be truncated error in Compliance
                Report.
              </li>
              <li>
                It was possible to enter a float value in the Window information
                of the Task Editor screen.
              </li>
              <li>Session Timeout was not reset on Tasks management screen.</li>
              <li>Some tasks do not appear in Unassigned Tasks Report</li>
              <li>
                Data Truncated error for TaskIds longer than 50 characters
              </li>
              <li>
                String or binary data would be truncated on Compliance Report
              </li>
              <li>
                Filter is not working for Downtime on Tasks Selection Screen
              </li>
              <li>
                Stops dont show up on Compliance Report for Team(s)/Routes
              </li>
              <li>
                Multiple Assignments Report was retuning wrong Team-Routes
                values
              </li>
              <li>
                Multiple Assignments and Unassigned Tasks reports grid were not
                cleared when changing the report selection
              </li>
              <li>
                ConfigLoader was still uploading Test Time in HHMM format
                instead of HH:MM
              </li>
            </ul>
          </Item>
          <Item title="v2.3.0 Released on 19-May-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>
                WARNING : A pre-script has to be run before upgrading to this
                version as there is data conversion to perform in the database.
              </li>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New SQL installation script is required.</li>
              <li>New prompts are required to run this version.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                Users are automatically logged in eCIL without entering user ans
                password if their NT information is filled in Proficy.
              </li>
              <li>New interfaces for Routes and Teams management.</li>
              <li>
                Several new reports to track Route, Teams and Users
                associations.
              </li>
              <li>New Unassigned Taks Report.</li>
              <li>New Multiple Assignments Report.</li>
              <li>
                Scheduling Errors Report is now accessible outside Admin area.
              </li>
              <li>
                Now using dedicated MESECIL SQL user instead of proficydbo.
              </li>
              <li>
                The scheduler now looks for the [Check Line Status] UDP to
                decide if it should check for the Line Status or not. This UDP
                is set on the eCIL Scheduler Model.
              </li>
              <li>
                In Version Management, the message to identify duplicate VMIds
                on a line was changed to be more self-explanatory.
              </li>
              <li>
                More specific error message in VM when duplicate VMIDs are found
                on a line or a module.
              </li>
              <li>
                Downtimes color in eMag report was changed to avoid confusion
                with Done Late tasks.
              </li>
              <li>Test Time is now saved as HH:MM in a Hour UDP in Proficy.</li>
              <li>
                Obsoleting a task now set the Is_Active field of the variable to
                zero.
              </li>
              <li>
                Users are now allowed to create new defects only on the most
                recent instance of a task.
              </li>
              <li>
                Duration and Long Task Name columns were added as available
                columns in Tasks Planning Report.
              </li>
              <li>
                Compliance Report can now be filtered to display only QFactor
                tasks.
              </li>
              <li>
                Q-Factor are now referred to new standard naming : Q-factor Type
                and Primary Q-Factor?
              </li>
              <li>
                In Version Mgmt and Tasks Mgmt, the grid is now automatically
                filtered to display Success/Error rows after a save.
              </li>
              <li>
                The scheduler now fully support Test Time on Multi-Day Tasks.
              </li>
              <li>Using DevExpress v9.3.4</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                In Version Management, when checking the existence of a task,
                the line was ignored, causing problem if there was already the
                same task name on the same unit name of another line. (v2.2.1
                Hotfix 1)
              </li>
              <li>
                Route Tasks admin screen was giving a timeout error on busy
                servers. (Ref Ticket # 28379628 on Oxnard) (v2.2.1 Hotfix 2)
              </li>
              <li>
                There was an error in the Proficy version detection. (v2.2.1
                Hotfix 3)
              </li>
              <li>
                If all tasks were removed from a route, the tasks associated
                with the route were not deleted. (v2.2.1 Hotfix 4)
              </li>
              <li>
                String or binary data would be truncated error on Team-Routes
                page, when editing a Team which has routes with more than 50
                characters. Adjusted to allow 150. (v2.2.1 Hotfix 5)
              </li>
              <li>
                VM screen was saving Test Time as hh:mm instead of hhmm in the
                database. (v2.2.1 Hotfix 6).
              </li>
              <li>
                Inactive Non-product-based tasks were scheduled and they should
                not. (v2.2.1 HotFix 6).
              </li>
              <li>
                Object Not Set error when saving the result of a Module Level
                comparison. (v2.2.1 HotFix 6).
              </li>
              <li>
                The end of the period was not correctly calculated on Report
                Parameters screens when selecting Next Month for 31 day months.
              </li>
              <li>
                @Value Parameter cannot be empty error message was displayed in
                VM, when saving an empty line version.
              </li>
              <li>Spec was still linked to a variable after obsoleting it.</li>
              <li>
                Empty group in VM was creating Unknown and Empty groups in
                Proficy. (v2.2.1 Hotfix 7).
              </li>
              <li>
                Errors when pushing some stored procedures on a SQL2005 server.
              </li>
              <li>Defects were incorrectly reported in Compliance Report.</li>
              <li>
                In VM, when selecting an empty line (No tasks) was returning an
                error.
              </li>
              <li>
                Stops were not showing on Compliance Report when Teams were
                selected.
              </li>
              <li>
                In Tasks Management, when selecting the first level of the Plant
                Model (Dept) and there was only one Dept, no task were returned.
              </li>
              <li>
                Late Date and Due date were not displayed in tasks list after a
                task already scheduled was set to inactive.
              </li>
            </ul>
          </Item>
          <Item title="v2.2.1 Released on 22-Feb-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New SQL installation script is required.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>Removed all references to fnCmn_UDPLookup SQL function</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Saving a task was failing in Tasks Management screen in Proficy
                4.4.1.
              </li>
              <li>
                When editing the Method information in Tasks Management screen,
                the modified information is incorrectly replaced by Hazards
                information.
              </li>
            </ul>
          </Item>
          <Item title="v2.2.0 Released on 17-Feb-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New prompts are required to run this version.</li>
              <li>New SQL installation script is required.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>Using DevExpress 9.3.3</li>
              <li>
                Tasks Planning Report was completely redesigned in a grid to
                allow more flexibility for the users.
              </li>
              <li>
                Wrap Mode is now available for the grid in Data Entry screen
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>Wrong validation of Task Frequency in Task Editor screen</li>
              <li>
                Task Frequency information was not shown in Task Details popup
                when configured in a UDP instead of in specs
              </li>
              <li>
                Javascript error in Internet Explorer 6 when opening Compliance
                Report
              </li>
              <li>
                Unable to export Cyrillic and Arabic characters in Tasks
                Planning Report
              </li>
              <li>
                In Routes Management screen, Save Route picture show a disable
                state even when the button is enabled
              </li>
              <li>
                Prompt error in log files when opening Tasks Management or
                Version Management screen
              </li>
              <li>
                View already exists message was displayed if a public view of
                another screen has the same description
              </li>
            </ul>
          </Item>
          <Item title="v2.1.1 Released on 21-Jan-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New prompts are required to run this version.</li>
              <li>New SQL installation script is required.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                Icons in menus are located on top of text instead of to the
                left, allowing more items visible on page width.
              </li>
              <li>
                A new menu interface is available for Custom Layout of the Tasks
                List grid, allowing more flexibility like each user setting its
                own Default View. Also, an admin can set the Default View for
                the entire site, which will be overriden by a user Default View.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Compliance Report was showing Service Columns which should be
                hidde.
              </li>
              <li>
                In Task Editor screen, Group could be left empty and was
                generating an error.
              </li>
              <li>
                Managers could access Tasks Management which is reserved for
                Admin.
              </li>
            </ul>
          </Item>
          <Item title="v2.1.0 Released on 12-Jan-2010">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version.
              </li>
              <li>SQL Stored Procedures must be updated.</li>
              <li>New prompts are required to run this version.</li>
              <li>New CDW and ConfigLoader files are required.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                In Version Management, inexisting Modules and Groups are
                automatically created with corresponding FL3 and FL4 information
                if required.
              </li>
              <li>
                Select All was previously selecting all tasks, even when out of
                a filter. Now select all selects only tasks displayed in the
                grid.
              </li>
              <li>
                Checkboxes are now hidden in Version Management screen for tasks
                having an error, or having been saved succesfully.
              </li>
              <li>
                CDW and Version Management now share the same Raw Data export
                file format.
              </li>
              <li>
                Line Version as well as Module Feature Version information is
                not automatically updated when saving.
              </li>
              <li>
                Changes are highlighted in grid of Tasks Management and Version
                Management.
              </li>
              <li>
                It is now possible to modify the FL when creating a new defect.
                This feature can be turned ON/OFF by setting the
                AllowDefectFLModification parameter in the WEB.Config file.
              </li>
              <li>
                New field added in installation screen to allow setting of SAP
                Url.
              </li>
              <li>
                Possibility to create new Production Groups and new Modules as
                well as FL3 and FL4 information directly from the Task Edition
                Popup.
              </li>
              <li>
                Users can now refresh the content of the Plant Model TreeView in
                the Tasks Management page.
              </li>
              <li>
                The footer of the grid in Version Management page now displays
                statistics about the number of tasks to Add/Modify/Obsolete.
              </li>
              <li>
                When saving a new line/module version, the information about
                Line Version and Module Feature Version automatically updates
                the corresponding UDPs in the Plant Model.
              </li>
              <li>
                The Task Name is now compared with information coming from Raw
                Data File and the Proficy variable name is modified accordingly.
              </li>
              <li>
                Tasks Planning Report column [Due Date] was renamed to
                [Projected Schedule Date] for better clarity.
              </li>
              <li>Using DevExpress v9.3.2.</li>
              <li>CDW and ConfigLoader files now support Proficy 4.4.1.</li>
              <li>
                Users can now create public Custom Views that can be seen (but
                not modified or deleted) by other users.
              </li>
              <li>
                Users can now select their own default view on each screen
                having Custom View feature.
              </li>
              <li>
                The scheduler now sets the Missed time one second before the end
                of the period. This solves issue where Missed were reported in
                the following period due to scheduler running within 5 minutes
                after the end of a period.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Compliance report was displaying an &quot;Object Not Set&quot;
                error when trying to switch from one page to another of any
                GridView.
              </li>
              <li>eMag report was showing obsoleted tasks.</li>
              <li>Compliance Report was showing obsolete tasks.</li>
              <li>
                Compliance Report was showing bad information when drilling down
                two different routes in Team mode.
              </li>
              <li>
                In Tasks Management TreeView, groups without tasks were not
                showing.
              </li>
              <li>
                Some prompts of the Master Page were not always translated.
              </li>
              <li>
                Editing the same information of a task a second time after
                saving it was not working.
              </li>
            </ul>
          </Item>
          <Item title="v2.0.0 Released on 19-Nov-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>DevExpress version 9.2.6 is used</li>
              <li>
                Version Management page now allows to update a Line/Module to a
                new version based on Raw Data Export file.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Compliance report now displays Pct Done as &quot;---&quot;
                instead of 0% when there are no tasks.
              </li>
            </ul>
          </Item>
          <Item title="v1.5.0 Released on 20-Oct-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>DevExpress version 9.2.6 is used</li>
              <li>
                A screen to adminster tasks (Add/Edit/Obsolete) is now
                available.
              </li>
              <li>
                A screen to easily identify Product-Based tasks incorrectly
                configured is now available.
              </li>
              <li>
                You can now edit the FL1-FL2-FL3-FL4 directly on the Plant Model
                of the Tasks Administration screen.
              </li>
              <li>
                Added new UDPs for versioning. Those fields are immediately
                editable from the admin screen.
              </li>
              <li>
                Line and Module versions can be seen on TreeView of admin
                screen.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Compliance report now displays Pct Done as &quot;---&quot;
                instead of 0% when there are no tasks.
              </li>
            </ul>
          </Item>
          <Item title="v1.4.3 Released on 30-Jun-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>DevExpress version 9.1.4</li>
              <li>
                eMag and Trend reports now show Done Late tasks in orange
                instead of yellow to make a distinction with tasks currently
                late.
              </li>
              <li>
                Compliance report now displays Pct Done as 100% instead of 0%
                when there are no tasks. This eliminates the red (out of limit)
                cell.
              </li>
              <li>
                The Tasks Planning report no longer includes already scheduled
                tasks.
              </li>
              <li>Ability to export Task Information popup to Excel.</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Object Not SET error when clicking Complete All button when the
                tasks list is displaying a page having less than the maximum
                tasks allowed per page.
              </li>
              <li>Tasks Selection screen was displaying obsoleted lines.</li>
              <li>
                The number of opened defects in the Compliance Report does not
                match the correct number of defects that were still opened
                during the report period.
              </li>
              <li>
                Done Late tasks do not appear yellow in Trend Report. They
                appear green, like done in time tasks
              </li>
              <li>
                On Compliance Report, if you select Route Details and Plant
                Model Details, the Trend and Route icon appears at team level.
              </li>
              <li>
                Tasks Planning report was returning tasks outside of report time
                range.
              </li>
              <li>
                Tasks Planning report was showing group header even if the group
                is empty.
              </li>
            </ul>
          </Item>
          <Item title="v1.4.2 Released on 16-Jun-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                Scheduler is now dealing with Valid Line Statuses which can
                starts by PR Out. Each line status is identified as
                Valid/Invalid by a new UDP on phrases of Line Status data type.
              </li>
              <li>
                Scheduler now using UDP history table for Task Frequency of
                tasks.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Stops always displayed as zero on the Compliance Report when the
                report is called for Team(s) or Route(s).
              </li>
              <li>
                Warning limits (Orange in Compliance Report) are never
                evaluated. Warnings are represented as User Limits.
              </li>
              <li>
                First column of eMag Report was showing numeric code instead of
                color-coded cell.
              </li>
              <li>
                eMag report was displaying Done Late tasks in green instead of
                yellow color-code.
              </li>
            </ul>
          </Item>
          <Item title="v1.4.1 Released on 28-May-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated. </li>
              <li>New Prompts are required.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                New Line Status configuration (Starting with PR In and PR Out)
                supported by the scheduler.
              </li>
              <li>
                Different STLS configurations supported by the scheduler (STLS
                unit configured on a different line, multiple STLS units per
                line).
              </li>
              <li>Site name is now displayed at the top of the main screen</li>
              <li>
                eCIL Report was not showing tasks having their Task Frequency
                set in a UDP instead of specs.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Some document link syntaxes could not be correctly opened. Also
                reduced page size by loading the link dynamically from server at
                runtime.
              </li>
              <li>
                Tasks List was displaying an error with tasks having a Long Task
                Name longer than 500 characters. This limit is increased to 2000
                characters.
              </li>
              <li>
                On Defects Screen, long task name was causing the window to
                become very large.
              </li>
              <li>
                Number of downtimes displayed in the Compliance Report could be
                incorrectly or not calculated depending of the entry level
                (Site/Dept/Line, etc...).
              </li>
            </ul>
          </Item>
          <Item title="v1.4.0 Released on 14-May-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                SAP connection information is encrypted in WEB.Config file.
              </li>
              <li>
                Scheduler now allows tasks to be scheduled based on a UDP
                instead of specs. The UDP overrides any spec value.
              </li>
              <li>
                Improvement of the main page and better uniformity of Tool Bars.
              </li>
              <li>Site navigation links added for every page</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                &gt;Error when changing task value with a user logged in a
                language different that server language.
              </li>
              <li>
                Tasks Planning report was displaying task results only in
                English
              </li>
              <li>
                Due Date of shiftly tasks was showing same as schedule date
              </li>
              <li>
                In different administration screens, when clicking the Add
                Selected and Remove Selected buttons without any selection, an
                error was thrown
              </li>
            </ul>
          </Item>
          <Item title="v1.3.2 Released on 17-Apr-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>Using new standardized UDP names.</li>
              <li>
                Permissions of a user set in eCIL All Lines security group are
                now overriden by permissions set to this user in a line level
                security group.
              </li>
              <li>
                Database connection information is now encrypted in Web.Config
                file.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>Minor fixes of code.</li>
            </ul>
          </Item>
          <Item title="v1.3.1 Released on 09-Mar-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>None.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>None.</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Error when going back to Tasks Selection from Tasks List, do
                another selection and open the Tasks List for a second time.
                (Object not set...)
              </li>
              <li>
                Headers of the Tasks List grid loose their translations when
                paging, reordering or selecting a different view.
              </li>
            </ul>
          </Item>
          <Item title="v1.3.0 Released on 04-Mar-2009">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                New functionnalities of the Scheduler (Multiday Fixed/Variable)
              </li>
              <li>
                The Tasks List now present the Route, Task Order and Team
                information
              </li>
              <li>
                Users have the possibility to switch between 4 predefined grid
                layouts (Plant Model, Routes, teams and FL)
              </li>
              <li>Users can create and save their own Tasks List layout</li>
              <li>
                Users can export the content of the Tasks List to Excel and
                Acrobat. All grid settings (columns, sorting, grouping) will be
                preserved.
              </li>
              <li>DevExpress version 8.3.4 integrated.</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Compliance Report displays wrong information from Master Unit
                and below when several routes are displayed.
              </li>
              <li>
                Functional Location correction on Defects screen (No longer
                based on PL_Desc, but on FL1).
              </li>
              <li>
                Code correction to prevent an error when missing dot (.) in the
                External Link of a task.
              </li>
              <li>
                Scheduler now continues to monitor opened tasks even if current
                product does not require to schedule that task
              </li>
            </ul>
          </Item>
          <Item title="v1.2.3 Released on 26-Nov-2008">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version.
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                <strong>None.</strong>
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                When changing the value of a task to OK on Polish server, an
                error is generated.
              </li>
              <li>
                On eMag report, when clicking on a downtime to have downtime
                details, some downtime details are not displayed.
              </li>
              <li>
                The headers of Sub Grids (Details) on Compliance Report are not
                translated.
              </li>
            </ul>
          </Item>
          <Item title="v1.2.2 Released on 11-Nov-2008">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version.
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>Task Description now shown in Task Card</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>.Object expected error in Main Menu (Intermittent)</li>
            </ul>
          </Item>
          <Item title="v1.2.1 Released on 31-Oct-2008">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version.
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>None.</li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Tasks stay cheched and highlighted in the grid after saving.
              </li>
              <li>
                Error Missing ) when running the eMag report on some modules.
              </li>
              <li>
                Error Missing ) when opening the Module level of Compliance
                Report on some modules.
              </li>
              <li>
                No task displayed when applying a filter in Tasks Selection
                screen.
              </li>
              <li>Task Info Popup is not always populated.</li>
            </ul>
          </Item>
          <Item title="v1.2.0 Released on 27-Oct-2008">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version.
              </li>
              <li>SQL Stored Procedures must be updated.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                Versions History is now accessible directly from the
                application.
              </li>
              <li>SAP integration completed.</li>
              <li>Possibility to add several defects on the same task.</li>
              <li>
                Now using STI PromptsManager.dll for all multilingual
                functionnalities.
              </li>
              <li>All changes from version 1.0.0 are now multilingual.</li>
              <li>DevExpress version 8.2.5 integrated.</li>
              <li>
                Using Prompts Manager version 2.0.0. Prompts can now be
                relocated dynamically without affecting the code.
              </li>
              <li>
                Tasks list is now presented in a new grid, allowing integrated
                filtering, sorting and grouping.
              </li>
              <li>
                It is now possible to set several tasks to &quot;OK&quot; at
                once.
              </li>
              <li>Supporting Group-Based and Role-Based Security </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                User messages are fixed (Like Route already exists). Previous
                version was showing a generic error 500 on production servers.
              </li>
              <li>
                Delete confirmation message was blank in Team-Users and
                Team-Routes administration pages. Fixed.
              </li>
              <li>
                Delete Route was giving an error : dbo.Local_PG_eCIL_RouteUsers
                does not exists. Fixed in Stored Procedure.
              </li>
              <li>Delete Route icon was always disabled one. Fixed.</li>
              <li>
                On TasksPlanningParameters page, the navigation information in
                the top of the page indicates navigation for Compliance instead
                of Tasks Planning. Fixed.
              </li>
              <li>
                When selecting an existing description for route or team, error
                trapping was working for new description, but incorrect for
                modifying an existing description for an already existing one.
                Fixed.
              </li>
              <li>
                When requesting eMag or Compliance Report more than once, data
                was retrieved twice each time from the database. DevExpress
                issue fixed.
              </li>
              <li>
                On Tasks Selection, when selecting Plant Model Selection, then
                another one, and selecting back Plant Model Selection, the
                Available Modules panel is visible with no line selected. Fixed.
              </li>
              <li>
                Issue corrected in Scheduling Engine. Multiday tasks were not
                scheduled during Planned Shutdown and they should. Fixed.
              </li>
              <li>
                SAP connection was attempted twice when clicking the Connect
                button of the SAP connection Popup.
              </li>
            </ul>
          </Item>
          <Item title="v1.1.0 Released on 03-Jan-2007">
            <h4>Release Notes</h4>
            <ul>
              <li>
                New SQL script installation is required to run this version.
              </li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                It is now possible to log off from any screen in the application
              </li>
              <li>
                There is a new &quot;About&quot; button in the Main Menu. This
                will allow to know the version of eCIL currently used.
              </li>
              <li>
                The report selection is back in the Main Menu. But it is still
                possible to access other reports directly from a report page.
              </li>
              <li>
                All reports are now presented in PopUp controls instead of
                directly on the page. This allows users to ask the same report
                with different parameters faster.
              </li>
              <li>
                Report parameters are now all visible at once. The Tab control
                for parameters is gone. The user has an overview of all
                parameters at once, and the number of clicks is reduced.
              </li>
              <li>
                Report parameters now have color indicators. Red when a
                parameter is missing and green when parameters supplied. Visual
                clue, more intuitive for users.
              </li>
              <li>
                A new hierarchy was created for Team/Routes. Now a Team can be
                associated to Routes, Users and Tasks. Routes can only be
                associated to Tasks, no longer Users.
              </li>
              <li>
                The Compliance report was modified to reflect the new
                Team/Routes hierarchy. The report can now be asked by Plant
                Model, by Route or by Team. Furthermore, in Team selection, we
                have the possibility to select Team/Plant Model and/or
                Team/Routes. It could give a total of 3 grids on the report.
                Compliance Summary, Compliance Team/Routes and Compliance
                Team/Tasks.
              </li>
              <li>
                Tasks Selection was modified to reflect the new Team/Routes
                structure. Users now have a list of Team(s) or Route(s) when
                selecting My Teams or My Routes option. But only Team(s) the
                user is member of will be displayed, as well as Route(s) member
                of their respective Team(s).
              </li>
              <li>
                Administration menu was modified. Route-Users screen is no
                longer available. Team-Routes screen was added in Teams
                Administration.
              </li>
              <li>
                When saving a Route or a Team, all leading and trailing blanks
                are removed to avoid duplicate description with only blank
                spaces as difference.
              </li>
              <li>
                A user can now be member of several teams. A flag is still
                indicating that the user is member of another team, but it will
                no longer be removed automatically from the other team as
                before.
              </li>
              <li>
                Tasks Planning report parameters has been personalized. Time
                options are now only in the future (Tomorrow, Next Week, Next
                Month, Next 30 Days, etc…). If User-Defined time option is
                selected, the period is locked between today and 30 days ahead.
              </li>
              <li>
                Tasks with an opened defect now appears at the top of the list
                in Compliance Report.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                eMag report can now be accessed by clicking on the eMag icon in
                Compliance Report at the Module Level. There was an issue with
                this in previous version.
              </li>
              <li>
                Color of upper reject limits has been corrected for Compliance
                Report. Some cells were not colored when out of specs.
              </li>
            </ul>
          </Item>
          <Item title="v1.0.1 Released on 28-Nov-2007">
            <h4>Release Notes</h4>
            <ul>
              <li>None.</li>
            </ul>
            <h4>New Features/Changes</h4>
            <ul>
              <li>
                Login text was changed to Login Screen to avoid confusion in
                Login Menu
              </li>
              <li>
                When selecting a parameter on Compliance or eMag, the next tab
                will be automatically selected.
              </li>
              <li>
                Added [Last 30 Days] period to the parameters selection of
                Compliance Report.
              </li>
            </ul>
            <h4>Resolved Issues</h4>
            <ul>
              <li>
                Fixed the navigation links missing on top of Tasks Planning
                Report page
              </li>
              <li>
                Fixed the timeout counter not reseting in Tasks Entry screen
                when using Popups without changing data
              </li>
              <li>
                On module selection of eMag Report, Line Level has a checkbox.
                Removed it.
              </li>
              <li>
                Select All Team/Routes on SelectReport page sometimes requires
                more than one click. Fixed.
              </li>
              <li>
                eMag report does not show tasks of the current day. Fixed.
              </li>
              <li>
                Tasks Planning report was reporting tasks out of selected
                period. Corrected Stored Procedure.
              </li>
              <li>
                When clicking on a defect (Red cell) in eMag Report, the defect
                details popup is empty. Fixed SP.
              </li>
            </ul>
          </Item>
          <Item title="v1.0.0 Released on 26-Nov-2007">
            <h4>Release Notes</h4>
            <ul>
              <li>First application installation.</li>
            </ul>
          </Item>
        </Accordion> */}
      </div>
    );
  }
}
