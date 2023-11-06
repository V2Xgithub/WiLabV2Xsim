import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoverageReport
import matlab.unittest.TestSuite;

% clear previous run files
try
    rmdir(fullfile(tempdir, "v2xsim_tests", "smoke"), 's');
catch me
    % do nothing
end
suite = TestSuite.fromPackage("v2xsim_tests.smoke");
runner = testrunner("textoutput");
sourceCodeFolder = ".";
reportFolder = "./coverageReport";
reportFormat = CoverageReport(reportFolder);
p = CodeCoveragePlugin.forFolder(sourceCodeFolder,"Producing",reportFormat, "IncludingSubfolders", true);
runner.addPlugin(p);
results = runner.run(suite);
