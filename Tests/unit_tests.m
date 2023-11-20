import matlab.unittest.TestSuite
import matlab.unittest.plugins.StopOnFailuresPlugin
% clear previous run files
try
    rmdir(fullfile(tempdir, "v2xsim_tests", "unit"), 's');
catch me
    % do nothing
end

suite = TestSuite.fromPackage("v2xsim_tests.unit", "IncludingSubpackages", true);
runner = testrunner("textoutput");
runner.addPlugin(StopOnFailuresPlugin)
results = runner.run(suite);
