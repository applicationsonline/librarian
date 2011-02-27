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



  @wip
  Scenario: A simple Cheffile with one cookbook with one dependency
    Given a directory named "cookbook-soures/main"
    Given a file named "cookbook-sources/main/metadata.yaml" with:
      """
      name: main
      version: 1.0.0
      dependencies:
        sub: 1.0.0
      """
    Given a directory named "cookbook-sources/sub"
    Given a file named "cookbook-sources/sub/metadata.yaml" with:
      """
      name: sub
      version: 1.0.0
      dependencies: {}
      """
    Given a file named "Cheffile" with:
      """
      path 'cookbook-sources'
      cookbook 'main'
      """
    When I run "librarian-chef install"
    Then the exit status should be 0
    And a directory named "cookbooks/main" should exist
    And the file "cookbooks/main/metadata.yaml" should contain exactly:
      """
      name: main
      version: 1.0.0
      dependencies:
        sub: 1.0.0
      """
    And a directory named "cookbooks/sub" should exist
    And the file "cookbooks/sub/metadata.yaml" should contain exactly:
      """
      name: sub
      version: 1.0.0
      dependencies: {}
      """



