Feature: cli/catalog



  Background:
    Given a directory named "cookbooks"



  Scenario: A simple Cheffile with one cookbook
    Given a directory named "cookbook-sources/apt"
    Given a file named "cookbook-sources/apt/metadata.yaml" with:
      """
      name: apt
      version: 1.0.0
      dependencies: { }
      """
    Given a file named "Cheffile" with:
      """
      cookbook 'apt',
        :path => 'cookbook-sources'
      """
    When I run "librarian-chef install"
    Then the exit status should be 0
    And a directory named "cookbooks/apt" should exist
    And the file "cookbooks/apt/metadata.yaml" should contain exactly:
      """
      name: apt
      version: 1.0.0
      dependencies: { }
      """



