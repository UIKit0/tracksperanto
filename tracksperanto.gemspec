# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tracksperanto}
  s.version = "1.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Julik Tarkhanov"]
  s.date = %q{2009-10-10}
  s.default_executable = %q{tracksperanto}
  s.description = %q{Tracksperanto is a universal 2D-track translator between many apps.}
  s.email = ["me@julik.nl"]
  s.executables = ["tracksperanto"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = [".DS_Store", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/tracksperanto", "lib/.DS_Store", "lib/export/base.rb", "lib/export/equalizer3.rb", "lib/export/equalizer4.rb", "lib/export/match_mover.rb", "lib/export/maya_live.rb", "lib/export/mux.rb", "lib/export/nuke_script.rb", "lib/export/pftrack.rb", "lib/export/pftrack_5.rb", "lib/export/shake_text.rb", "lib/export/syntheyes.rb", "lib/import/base.rb", "lib/import/equalizer3.rb", "lib/import/equalizer4.rb", "lib/import/flame_stabilizer.rb", "lib/import/match_mover.rb", "lib/import/maya_live.rb", "lib/import/nuke_script.rb", "lib/import/pftrack.rb", "lib/import/shake_grammar/catcher.rb", "lib/import/shake_grammar/lexer.rb", "lib/import/shake_script.rb", "lib/import/shake_text.rb", "lib/import/syntheyes.rb", "lib/middleware/base.rb", "lib/middleware/golden.rb", "lib/middleware/reformat.rb", "lib/middleware/scaler.rb", "lib/middleware/shift.rb", "lib/middleware/slipper.rb", "lib/pipeline/base.rb", "lib/tracksperanto.rb", "lib/tracksperanto/block_init.rb", "lib/tracksperanto/casts.rb", "lib/tracksperanto/const_name.rb", "lib/tracksperanto/ext_io.rb", "lib/tracksperanto/format_detector.rb", "lib/tracksperanto/keyframe.rb", "lib/tracksperanto/safety.rb", "lib/tracksperanto/simple_export.rb", "lib/tracksperanto/tracker.rb", "lib/tracksperanto/zip_tuples.rb", "test/.DS_Store", "test/export/.DS_Store", "test/export/README_EXPORT_TESTS.txt", "test/export/samples/ref_Mayalive.txt", "test/export/samples/ref_Mayalive_CustomAspect.txt", "test/export/samples/ref_NukeScript.nk", "test/export/samples/ref_NukeScript.nk.autosave", "test/export/samples/ref_PFTrack.2dt", "test/export/samples/ref_PFTrack5.2dt", "test/export/samples/ref_ShakeText.txt", "test/export/samples/ref_Syntheyes.txt", "test/export/samples/ref_equalizer.txt", "test/export/samples/ref_equalizer3.txt", "test/export/samples/ref_matchmover.rz2", "test/export/test_equalizer3_export.rb", "test/export/test_equalizer_export.rb", "test/export/test_match_mover_export.rb", "test/export/test_maya_live_export.rb", "test/export/test_mux.rb", "test/export/test_nuke_export.rb", "test/export/test_pftrack5_export.rb", "test/export/test_pftrack_export.rb", "test/export/test_shake_export.rb", "test/export/test_syntheyes_export.rb", "test/helper.rb", "test/import/.DS_Store", "test/import/samples/.DS_Store", "test/import/samples/3de_export_cube.txt", "test/import/samples/3de_export_v3.txt", "test/import/samples/flyover2DP_syntheyes.txt", "test/import/samples/four_tracks_in_one_matchmove.shk", "test/import/samples/four_tracks_in_one_stabilizer.shk", "test/import/samples/fromCombustion_fromMidClip_wSnap.stabilizer", "test/import/samples/garage.2dt", "test/import/samples/hugeFlameSetup.stabilizer", "test/import/samples/kipPointsMatchmover.rz2", "test/import/samples/mayalive_kipShot.txt", "test/import/samples/megaTrack.action.3dtrack.stabilizer", "test/import/samples/one_shake_tracker.txt", "test/import/samples/one_shake_tracker_from_first.txt", "test/import/samples/one_tracker_with_break.nk", "test/import/samples/one_tracker_with_break_in_grp.nk", "test/import/samples/shake_tracker_nodes.shk", "test/import/samples/shake_tracker_nodes_to_syntheyes.txt", "test/import/samples/sourcefile_pftrack.2dt", "test/import/samples/three_tracks_in_one_stabilizer.shk", "test/import/samples/two_shake_trackers.txt", "test/import/samples/two_tracks_in_one_tracker.shk", "test/import/test_3de_import.rb", "test/import/test_3de_import3.rb", "test/import/test_flame_import.rb", "test/import/test_match_mover_import.rb", "test/import/test_maya_live_import.rb", "test/import/test_nuke_import.rb", "test/import/test_pftrack_import.rb", "test/import/test_shake_catcher.rb", "test/import/test_shake_lexer.rb", "test/import/test_shake_script_import.rb", "test/import/test_shake_text_import.rb", "test/import/test_syntheyes_import.rb", "test/middleware/test_golden_middleware.rb", "test/middleware/test_reformat_middleware.rb", "test/middleware/test_scaler_middleware.rb", "test/middleware/test_shift_middleware.rb", "test/middleware/test_slip_middleware.rb", "test/test_const_name.rb", "test/test_extio.rb", "test/test_format_detector.rb", "test/test_keyframe.rb", "test/test_simple_export.rb", "test/test_tracker.rb", "tracksperanto.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://guerilla-di.org/tracksperanto}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{guerilla-di}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Tracksperanto is a universal 2D-track translator between many apps.}
  s.test_files = ["test/export/test_equalizer3_export.rb", "test/export/test_equalizer_export.rb", "test/export/test_match_mover_export.rb", "test/export/test_maya_live_export.rb", "test/export/test_mux.rb", "test/export/test_nuke_export.rb", "test/export/test_pftrack5_export.rb", "test/export/test_pftrack_export.rb", "test/export/test_shake_export.rb", "test/export/test_syntheyes_export.rb", "test/import/test_3de_import.rb", "test/import/test_3de_import3.rb", "test/import/test_flame_import.rb", "test/import/test_match_mover_import.rb", "test/import/test_maya_live_import.rb", "test/import/test_nuke_import.rb", "test/import/test_pftrack_import.rb", "test/import/test_shake_catcher.rb", "test/import/test_shake_lexer.rb", "test/import/test_shake_script_import.rb", "test/import/test_shake_text_import.rb", "test/import/test_syntheyes_import.rb", "test/middleware/test_golden_middleware.rb", "test/middleware/test_reformat_middleware.rb", "test/middleware/test_scaler_middleware.rb", "test/middleware/test_shift_middleware.rb", "test/middleware/test_slip_middleware.rb", "test/test_const_name.rb", "test/test_extio.rb", "test/test_format_detector.rb", "test/test_keyframe.rb", "test/test_simple_export.rb", "test/test_tracker.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<flexmock>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 2.3.3"])
    else
      s.add_dependency(%q<flexmock>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 2.3.3"])
    end
  else
    s.add_dependency(%q<flexmock>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 2.3.3"])
  end
end
